# Variables for GCP Infrastructure (Disaster Recovery)

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Network Variables
variable "gke_subnet_cidr" {
  description = "CIDR block for GKE subnet"
  type        = string
  default     = "10.1.0.0/20"
}

variable "gke_pods_cidr" {
  description = "CIDR block for GKE pods"
  type        = string
  default     = "10.1.16.0/20"
}

variable "gke_services_cidr" {
  description = "CIDR block for GKE services"
  type        = string
  default     = "10.1.32.0/20"
}

variable "gke_master_cidr" {
  description = "CIDR block for GKE master"
  type        = string
  default     = "10.1.48.0/28"
}

variable "sql_subnet_cidr" {
  description = "CIDR block for Cloud SQL subnet"
  type        = string
  default     = "10.1.64.0/20"
}

# GKE Variables
variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "gke_node_count" {
  description = "Initial number of GKE nodes per zone"
  type        = number
  default     = 1
}

variable "gke_min_nodes" {
  description = "Minimum number of GKE nodes per zone"
  type        = number
  default     = 1
}

variable "gke_max_nodes" {
  description = "Maximum number of GKE nodes per zone"
  type        = number
  default     = 5
}

variable "gke_disk_size" {
  description = "Disk size for GKE nodes (GB)"
  type        = number
  default     = 100
}

# Cloud SQL Variables
variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "sql_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-standard-2"
}

variable "sql_disk_size" {
  description = "Cloud SQL disk size (GB)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "ace_db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "ace_admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Redis Variables
variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "REDIS_7_0"
}

variable "redis_memory_size" {
  description = "Redis memory size (GB)"
  type        = number
  default     = 4
}

variable "redis_ip_range" {
  description = "Reserved IP range for Redis"
  type        = string
  default     = "10.1.80.0/29"
}

# Domain Variables
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "ace-dr.example.com"
}