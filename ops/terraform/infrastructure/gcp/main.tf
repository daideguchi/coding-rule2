# AI Compliance Engine - GCP Infrastructure (Disaster Recovery)
# Phase 1: DR Environment Setup

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Provider configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "storage.googleapis.com",
    "dns.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ])

  project = var.gcp_project_id
  service = each.key

  disable_dependent_services = true
  disable_on_destroy        = false
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "ace-vpc-${var.environment}"
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"

  depends_on = [google_project_service.services]
}

# Subnet for GKE
resource "google_compute_subnetwork" "gke" {
  name          = "ace-gke-subnet-${var.environment}"
  network       = google_compute_network.main.id
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.gcp_region

  secondary_ip_range {
    range_name    = "ace-pods-${var.environment}"
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = "ace-services-${var.environment}"
    ip_cidr_range = var.gke_services_cidr
  }

  private_ip_google_access = true
}

# Subnet for Cloud SQL
resource "google_compute_subnetwork" "sql" {
  name          = "ace-sql-subnet-${var.environment}"
  network       = google_compute_network.main.id
  ip_cidr_range = var.sql_subnet_cidr
  region        = var.gcp_region

  private_ip_google_access = true
}

# Cloud Router for NAT
resource "google_compute_router" "main" {
  name    = "ace-router-${var.environment}"
  region  = var.gcp_region
  network = google_compute_network.main.id
}

# Cloud NAT
resource "google_compute_router_nat" "main" {
  name                               = "ace-nat-${var.environment}"
  router                            = google_compute_router.main.name
  region                            = var.gcp_region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_internal" {
  name    = "ace-allow-internal-${var.environment}"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.gke_subnet_cidr,
    var.gke_pods_cidr,
    var.gke_services_cidr,
    var.sql_subnet_cidr
  ]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "ace-allow-ssh-${var.environment}"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP ranges
  target_tags   = ["ssh-allowed"]
}

# KMS Key Ring and Keys
resource "google_kms_key_ring" "main" {
  name     = "ace-keyring-${var.environment}"
  location = var.gcp_region

  depends_on = [google_project_service.services]
}

resource "google_kms_crypto_key" "main" {
  name     = "ace-key-${var.environment}"
  key_ring = google_kms_key_ring.main.id

  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# Service Account for GKE
resource "google_service_account" "gke" {
  account_id   = "ace-gke-${var.environment}"
  display_name = "ACE GKE Service Account"
  description  = "Service account for GKE cluster"
}

resource "google_project_iam_member" "gke_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  ])

  project = var.gcp_project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke.email}"
}

# GKE Cluster
resource "google_container_cluster" "main" {
  name     = "ace-cluster-${var.environment}"
  location = var.gcp_region

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.gke.id

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Networking configuration
  ip_allocation_policy {
    cluster_secondary_range_name  = "ace-pods-${var.environment}"
    services_secondary_range_name = "ace-services-${var.environment}"
  }

  # Network policy
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.gke_master_cidr
  }

  # Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Database encryption
  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.main.id
  }

  # Cluster features
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 100
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 100
    }
  }

  # Monitoring and logging
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = "2023-01-01T03:00:00Z"
      end_time   = "2023-01-01T07:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA"
    }
  }

  # Security hardening
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Addons
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
    dns_cache_config {
      enabled = true
    }
  }

  depends_on = [
    google_project_service.services,
    google_project_iam_member.gke_roles
  ]
}

# GKE Node Pool
resource "google_container_node_pool" "main" {
  name       = "ace-node-pool-${var.environment}"
  location   = var.gcp_region
  cluster    = google_container_cluster.main.name
  node_count = var.gke_node_count

  # Node configuration
  node_config {
    machine_type = var.gke_machine_type
    disk_size_gb = var.gke_disk_size
    disk_type    = "pd-ssd"
    image_type   = "COS_CONTAINERD"

    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Security
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      environment = var.environment
      project     = "ace"
    }

    tags = ["ace-node"]
  }

  # Auto-scaling
  autoscaling {
    min_node_count = var.gke_min_nodes
    max_node_count = var.gke_max_nodes
  }

  # Management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "ace-db-${var.environment}"
  database_version = var.postgres_version
  region           = var.gcp_region

  settings {
    tier              = var.sql_tier
    availability_type = "REGIONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.sql_disk_size
    disk_autoresize   = true

    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.gcp_region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = 7 # Sunday
      hour         = 3
      update_track = "stable"
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.main.id
      enable_private_path_for_google_cloud_services = true
    }

    # Database flags
    database_flags {
      name  = "log_statement"
      value = "all"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
  }

  deletion_protection = true

  depends_on = [
    google_project_service.services,
    google_service_networking_connection.private_vpc_connection
  ]
}

# Private VPC connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "ace-private-ip-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [google_project_service.services]
}

# Cloud SQL Database
resource "google_sql_database" "main" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
}

# Cloud SQL User
resource "google_sql_user" "main" {
  name     = var.db_username
  instance = google_sql_database_instance.main.name
  password = var.db_password
}

# Redis Instance (Memorystore)
resource "google_redis_instance" "main" {
  name           = "ace-redis-${var.environment}"
  memory_size_gb = var.redis_memory_size
  region         = var.gcp_region

  authorized_network = google_compute_network.main.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version     = var.redis_version
  display_name      = "ACE Redis Instance"
  reserved_ip_range = var.redis_ip_range

  auth_enabled      = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 3
        minutes = 0
      }
    }
  }

  depends_on = [
    google_project_service.services,
    google_service_networking_connection.private_vpc_connection
  ]
}

# Cloud Storage Bucket
resource "google_storage_bucket" "main" {
  name     = "ace-storage-${var.environment}-${random_string.bucket_suffix.result}"
  location = var.gcp_region

  # Storage class
  storage_class = "STANDARD"

  # Versioning
  versioning {
    enabled = true
  }

  # Encryption
  encryption {
    default_kms_key_name = google_kms_crypto_key.main.id
  }

  # Lifecycle
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Security
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  depends_on = [google_project_service.services]
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Cloud DNS Managed Zone
resource "google_dns_managed_zone" "main" {
  name     = "ace-zone-${var.environment}"
  dns_name = "${var.domain_name}."

  description = "DNS zone for ACE ${var.environment}"

  dnssec_config {
    state         = "on"
    non_existence = "nsec3"
  }

  depends_on = [google_project_service.services]
}

# Outputs
output "gke_cluster_name" {
  value = google_container_cluster.main.name
}

output "gke_cluster_endpoint" {
  value = google_container_cluster.main.endpoint
}

output "sql_instance_connection_name" {
  value = google_sql_database_instance.main.connection_name
}

output "sql_instance_private_ip" {
  value = google_sql_database_instance.main.private_ip_address
}

output "redis_host" {
  value = google_redis_instance.main.host
}

output "redis_port" {
  value = google_redis_instance.main.port
}

output "storage_bucket_name" {
  value = google_storage_bucket.main.name
}

output "dns_zone_name" {
  value = google_dns_managed_zone.main.name
}

output "kms_key_id" {
  value = google_kms_crypto_key.main.id
}