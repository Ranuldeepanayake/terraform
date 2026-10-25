# Comprehensive Provisioned Mode Example
# This file documents all available configuration options for provisioned mode.
# Uncomment or modify options as needed for your use case.

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Generate a random auth token
resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

# Comprehensive provisioned cluster example
module "elasticache_valkey_provisioned" {
  source = "../"

  # ==========================================================================
  # Deployment Mode (Required)
  # ==========================================================================

  deployment_mode = "provisioned"

  # ==========================================================================
  # Cluster Identity and Configuration (Required)
  # ==========================================================================

  cluster_id     = "prod-primary-cache"
  engine_version = "8.0"  # Options: 8.0, 9.0, etc.

  # ==========================================================================
  # Node Configuration (Provisioned Only)
  # ==========================================================================

  node_type       = "cache.m7g.large"  # Development: cache.t4g.micro, cache.t4g.small
                                        # Production: cache.m7g.large, cache.r7g.large, cache.r7g.xlarge, cache.r7g.2xlarge
  num_cache_nodes = 2                   # 1 for single-node, 2+ for multi-node with replication

  # ==========================================================================
  # High Availability and Replication (Provisioned Only)
  # ==========================================================================

  multi_az_enabled           = true   # Enable Multi-AZ for HA
  automatic_failover_enabled = true   # Enable automatic failover (requires Multi-AZ or 2+ nodes)

  # ==========================================================================
  # Parameter Group Configuration (Provisioned Only)
  # ==========================================================================
  # Set parameter_group_name = null to let the module create a custom group.
  # Or reference an existing group name if it exists in your region.
  # See PARAMETER-GROUP-SETUP.md for details and troubleshooting.
  # ==========================================================================

  # Option 1: Let module create custom group
  parameter_group_name   = null
  parameter_group_family = "valkey8"
  parameters             = {}

  # Option 2: Use existing default (if available)
  # parameter_group_name = "default.valkey8"  # Try this first
  # parameter_group_name = "default.valkey9"  # Or for Valkey 9.0

  # ==========================================================================
  # Networking
  # ==========================================================================

  subnet_ids = [
    "subnet-089b9610c4dee02f4",
    "subnet-0776c6b9deb42264e"
  ]

  subnet_group_name = "prod-cache-subnet-group"  # If null, auto-generated
  port              = 6379                       # Default Valkey port

  # ==========================================================================
  # Security Group Configuration
  # ==========================================================================

  vpc_id                = "vpc-02ae59b36d4cf20d7"
  create_security_group = true  # If false, provide security_group_ids

  security_group_ingress_rules = {
    from_app_servers = {
      description                  = "Allow from app servers"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = "sg-0a1b2c3d4e5f6g7h8"
    }
    from_another_sg = {
      description                  = "Allow from another service"
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
    allow_all_ipv4 = {
      description = "Allow all outbound IPv4"
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  # ==========================================================================
  # Authentication (Optional)
  # ==========================================================================

  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result  # 16-128 characters
  auth_secret_name   = "prod/cache/auth-token"             # Custom secret name

  # ==========================================================================
  # Encryption (Optional)
  # ==========================================================================

  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  transit_encryption_enabled = true
  transit_encryption_mode    = "required"  # Options: "preferred", "required"

  # ==========================================================================
  # CloudWatch Logging (Provisioned Only)
  # ==========================================================================

  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 30

  slow_log_group_name    = "/prod/cache/slow-log"    # If null, auto-generated
  engine_log_group_name  = "/prod/cache/engine-log"  # If null, auto-generated

  # log_delivery_configuration = {
  #   "slow-log" = {
  #     enabled                   = true
  #     log_format                = "json"
  #     cloudwatch_log_group_name = "/prod/cache/slow-log"
  #   }
  #   "engine-log" = {
  #     enabled                   = true
  #     log_format                = "json"
  #     cloudwatch_log_group_name = "/prod/cache/engine-log"
  #   }
  # }

  # ==========================================================================
  # Snapshots and Backups (Provisioned Only, single-node only)
  # ==========================================================================

  snapshot_retention_limit = 7            # 0-35 days, 0 to disable
  snapshot_window          = "02:00-03:00"

  # ==========================================================================
  # Maintenance and Upgrades (Provisioned Only)
  # ==========================================================================

  maintenance_window         = "sun:03:00-sun:04:00"
  auto_minor_version_upgrade = true
  apply_immediately          = false  # true to apply changes immediately (may cause downtime)

  # ==========================================================================
  # SNS Notifications and Alarms
  # ==========================================================================

  create_sns_topic      = true
  alert_email_addresses = ["ops@company.com", "sre@company.com"]
  # notification_topic_arn = "arn:aws:sns:us-east-1:123456789012:alerts"  # Use existing topic

  # ==========================================================================
  # CloudWatch Alarms (Provisioned Only)
  # ==========================================================================

  create_alarms               = true
  alarm_cpu_threshold         = 75      # CPU % threshold
  alarm_eviction_threshold    = 1000    # Evictions per minute
  alarm_connection_threshold  = 1000    # Client connections
  alarm_memory_threshold      = 80      # Memory usage %

  # Custom alarms
  custom_alarms = {
    high_network_in = {
      metric_name         = "NetworkBytesIn"
      namespace           = "AWS/ElastiCache"
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 2
      comparison_operator = "GreaterThanThreshold"
      threshold           = 5000000000  # 5 GB
      alarm_description   = "Alert when network bytes in exceeds 5 GB"
    }
    high_swap_usage = {
      metric_name         = "SwapUsage"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 52428800  # 50 MB
      alarm_description   = "Alert when swap usage exceeds 50 MB"
    }
  }

  # ==========================================================================
  # Tags
  # ==========================================================================

  tags = {
    Name            = "prod-primary-cache"
    Environment     = "production"
    ManagedBy       = "terraform"
    CostCenter      = "engineering"
    Application     = "api-backend"
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "cluster_endpoint" {
  description = "Valkey cluster endpoint"
  value       = module.elasticache_valkey_provisioned.primary_endpoint
}

output "cluster_arn" {
  description = "Cluster ARN"
  value       = module.elasticache_valkey_provisioned.cluster_arn
}

output "auth_secret_arn" {
  description = "Auth token secret ARN"
  value       = module.elasticache_valkey_provisioned.auth_secret_arn
}

output "auth_secret_name" {
  description = "Auth token secret name"
  value       = module.elasticache_valkey_provisioned.auth_secret_name
}

output "log_groups" {
  description = "CloudWatch log group names"
  value = {
    slow_log   = module.elasticache_valkey_provisioned.slow_log_group_name
    engine_log = module.elasticache_valkey_provisioned.engine_log_group_name
  }
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs"
  value = {
    cpu         = module.elasticache_valkey_provisioned.alarm_cpu_utilization_arn
    evictions   = module.elasticache_valkey_provisioned.alarm_evictions_arn
    connections = module.elasticache_valkey_provisioned.alarm_connections_arn
    memory      = module.elasticache_valkey_provisioned.alarm_memory_usage_arn
    engine_cpu  = module.elasticache_valkey_provisioned.alarm_engine_cpu_arn
  }
}

output "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  value       = module.elasticache_valkey_provisioned.sns_topic_arn
}

output "alert_subscriptions" {
  description = "Email addresses subscribed to alerts"
  value       = module.elasticache_valkey_provisioned.alert_email_subscriptions
}
