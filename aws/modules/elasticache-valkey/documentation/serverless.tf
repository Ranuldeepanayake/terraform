# Comprehensive Serverless Mode Example
# This file documents all available configuration options for serverless mode.
# Uncomment or modify options as needed for your use case.

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Comprehensive serverless cache example
module "elasticache_valkey_serverless" {
  source = "../"

  # ==========================================================================
  # Deployment Mode (Required)
  # ==========================================================================

  deployment_mode = "serverless"

  # ==========================================================================
  # Cluster Identity and Configuration (Required)
  # ==========================================================================

  cluster_id     = "prod-serverless-cache"
  engine_version = "8.0"  # Options: 8.0, 9.0, etc.

  # ==========================================================================
  # Serverless Capacity Configuration
  # ==========================================================================

  serverless_cache_size = 16  # Options: 1, 2, 4, 8, 16, 32, 64, 128, 256 (GB)
                              # Start small and scale up based on actual usage

  # ==========================================================================
  # Networking
  # ==========================================================================

  subnet_ids = [
    "subnet-089b9610c4dee02f4",
    "subnet-0776c6b9deb42264e"
  ]
  # Note: Serverless automatically spans multiple AZs - no configuration needed

  port  = 6379  # Default Valkey port
  vpc_id = "vpc-02ae59b36d4cf20d7"

  # ==========================================================================
  # Security Group Configuration
  # ==========================================================================

  create_security_group = true  # If false, provide security_group_ids

  security_group_ingress_rules = {
    from_app_servers = {
      description                  = "Allow from app servers"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = "sg-0a1b2c3d4e5f6g7h8"
    }
    from_internal_services = {
      description                  = "Allow from internal services"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = "sg-1a2b3c4d5e6f7g8h9"
    }
    # from_cidr = {
    #   description = "Allow from specific CIDR"
    #   from_port   = 6379
    #   to_port     = 6379
    #   protocol    = "tcp"
    #   cidr_ipv4   = "10.0.0.0/8"
    # }
  }

  security_group_egress_rules = {
    allow_all = {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  # ==========================================================================
  # Encryption (Optional)
  # ==========================================================================
  # Note: Serverless supports at-rest encryption only (no transit encryption option)

  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  # If null, uses AWS-managed key

  # ==========================================================================
  # Serverless-Specific Features NOT Supported
  # ==========================================================================
  # The following provisioned-only features are IGNORED in serverless mode:
  #
  # - Multi-AZ control (automatic, built-in)
  # - Automatic failover (built-in)
  # - Parameter groups (AWS-managed)
  # - Custom parameters
  # - Snapshots
  # - CloudWatch Logs (provisioned only)
  # - CloudWatch Alarms (provisioned only)
  # - SNS Notifications (provisioned only)
  # - Transit encryption (not available in serverless)

  # ==========================================================================
  # Settings that CAN be used but have limited effect in serverless
  # ==========================================================================

  # Auth token is NOT supported in serverless - commented out
  # auth_token_enabled = false  # Serverless does not support AUTH tokens

  # Logging is provisioned-only
  # cloudwatch_log_enabled = false  # Not available in serverless

  # Alarms are provisioned-only
  # create_alarms = false  # Not available in serverless

  # SNS topics are provisioned-only
  # create_sns_topic = false  # Not available in serverless

  # ==========================================================================
  # Tags
  # ==========================================================================

  tags = {
    Name            = "prod-serverless-cache"
    Environment     = "production"
    ManagedBy       = "terraform"
    CostCenter      = "engineering"
    Application     = "api-backend"
    DeploymentMode  = "serverless"
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "serverless_endpoint" {
  description = "Serverless cache endpoint"
  value       = module.elasticache_valkey_serverless.primary_endpoint
}

output "serverless_address" {
  description = "Serverless cache DNS address"
  value       = module.elasticache_valkey_serverless.cluster_address
}

output "serverless_port" {
  description = "Serverless cache port"
  value       = module.elasticache_valkey_serverless.cluster_port
}

output "serverless_arn" {
  description = "Serverless cache ARN"
  value       = module.elasticache_valkey_serverless.cluster_arn
}

output "serverless_cache_size" {
  description = "Serverless cache maximum capacity in GB"
  value       = module.elasticache_valkey_serverless.serverless_cache_size
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.elasticache_valkey_serverless.security_group_id
}

# =============================================================================
# Notes on Serverless Mode
# =============================================================================
#
# ADVANTAGES:
# - No manual node management or sizing
# - Automatic scaling based on demand
# - Built-in Multi-AZ high availability (always enabled)
# - Automatic backups and failover
# - Pay-per-use pricing model
# - Lower operational overhead
#
# LIMITATIONS:
# - No authentication tokens
# - No custom parameter tuning
# - No snapshots (automatic backup only)
# - No CloudWatch Logs
# - No CloudWatch Alarms
# - No SNS notifications
# - No control over failover behavior
# - No multi-shard cluster mode (single shard only)
#
# CAPACITY PLANNING:
# - Start with smaller cache size (e.g., 1-4 GB)
# - Monitor actual usage via CloudWatch metrics
# - Scale up only when needed
# - AWS scales reads automatically; writes scale with storage
#
# COST OPTIMIZATION:
# - Use serverless for workloads with unpredictable traffic patterns
# - Use provisioned for stable, predictable workloads
# - Compare TCO: provisioned fixed cost vs serverless variable cost
