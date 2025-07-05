# AI Compliance Engine - AWS Infrastructure
# Phase 1: Foundation Infrastructure Setup

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
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
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "ai-compliance-engine"
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ace-vpc-${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ace-igw-${var.environment}"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "ace-public-subnet-${count.index + 1}-${var.environment}"
    Type = "public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "ace-private-subnet-${count.index + 1}-${var.environment}"
    Type = "private"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "ace-nat-eip-${count.index + 1}-${var.environment}"
  }
}

resource "aws_nat_gateway" "main" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "ace-nat-${count.index + 1}-${var.environment}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "ace-public-rt-${var.environment}"
  }
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "ace-private-rt-${count.index + 1}-${var.environment}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Groups
resource "aws_security_group" "eks_cluster" {
  name        = "ace-eks-cluster-${var.environment}"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ace-eks-cluster-sg-${var.environment}"
  }
}

resource "aws_security_group" "rds" {
  name        = "ace-rds-${var.environment}"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "ace-rds-sg-${var.environment}"
  }
}

resource "aws_security_group" "redis" {
  name        = "ace-redis-${var.environment}"
  description = "Security group for Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "ace-redis-sg-${var.environment}"
  }
}

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description         = "KMS key for AI Compliance Engine"
  deletion_window_in_days = 7
  enable_key_rotation = true

  tags = {
    Name = "ace-kms-key-${var.environment}"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/ace-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# S3 Bucket for storage
resource "aws_s3_bucket" "main" {
  bucket = "ace-storage-${var.environment}-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "ace-cluster-${var.environment}"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.eks_public_access_cidrs
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.main.arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]

  tags = {
    Name = "ace-eks-cluster-${var.environment}"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "ace-nodes-${var.environment}"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id

  ami_type        = var.node_ami_type
  capacity_type   = var.node_capacity_type
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = {
    Name = "ace-eks-nodegroup-${var.environment}"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "ace-db-subnet-group-${var.environment}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "ace-db-subnet-group-${var.environment}"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "ace-db-${var.environment}"

  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.main.arn

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = false
  final_snapshot_identifier = "ace-db-final-snapshot-${var.environment}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn

  tags = {
    Name = "ace-db-${var.environment}"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "ace-cache-subnet-group-${var.environment}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "ace-cache-subnet-group-${var.environment}"
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "ace-redis-${var.environment}"
  description                = "Redis cluster for AI Compliance Engine"

  port                = 6379
  parameter_group_name = "default.redis7"
  engine_version      = var.redis_version
  node_type           = var.redis_node_type

  num_cache_clusters = var.redis_num_cache_nodes
  
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  snapshot_retention_limit = 7
  snapshot_window         = "03:00-05:00"

  tags = {
    Name = "ace-redis-${var.environment}"
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.main.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.main.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "ace-cloudfront-${var.environment}"
  }
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "OAI for ACE ${var.environment}"
}

# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = "ace-hosted-zone-${var.environment}"
  }
}

# Output values
output "vpc_id" {
  value = aws_vpc.main.id
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "s3_bucket_name" {
  value = aws_s3_bucket.main.bucket
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.main.domain_name
}

output "route53_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "kms_key_id" {
  value = aws_kms_key.main.key_id
}