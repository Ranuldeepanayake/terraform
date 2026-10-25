# Provisioned Single-Instance Example

This example demonstrates how to deploy an ElastiCache Valkey cluster in **provisioned mode with a single node**. Single-node clusters are ideal for development, testing, and non-critical workloads where high availability is not required.

## Key Characteristics

- **Single Node**: No replication, no failover
- **Snapshots**: Supported (backup and restore)
- **Maintenance**: Can be scheduled without impact to availability
- **Cost**: Lower than multi-node clusters
- **Use Case**: Development, testing, staging environments

---

## Minimal Single-Node Setup

```hcl
module "valkey_single_node" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "dev-cache"
  engine_version  = "8.0"
  node_type       = "cache.t4g.micro"
  num_cache_nodes = 1

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  tags = {
    Environment = "dev"
  }
}

output "cache_endpoint" {
  value = module.valkey_single_node.primary_endpoint
}
```

---

## Single-Node with Basic Security (AUTH + TLS)

```hcl
# AUTH tokens REQUIRE transit encryption - they cannot be used without TLS
resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "valkey_single_node_secure" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "staging-cache"
  engine_version  = "8.0"
  node_type       = "cache.t4g.small"
  num_cache_nodes = 1

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  # Use null to let module create custom parameter group
  # Or set to existing default: "default.valkey8", "default.valkey9", etc.
  parameter_group_name = null
  parameter_group_family = "valkey8"
  parameters = {}

  # Security
  create_security_group = true
  security_group_ingress_rules = {
    from_app = {
      description                  = "Allow from app servers"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.app.id
    }
  }

  # Authentication - REQUIRES transit encryption
  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = "staging/cache/token"

  # Transit Encryption - REQUIRED for AUTH tokens
  transit_encryption_enabled = true
  transit_encryption_mode    = "preferred"

  tags = {
    Environment = "staging"
  }
}

output "cache_endpoint" {
  value = module.valkey_single_node_secure.primary_endpoint
}

output "auth_secret_arn" {
  value = module.valkey_single_node_secure.auth_secret_arn
}
```

---

## Single-Node with Encryption & Snapshots

```hcl
# Create service-linked role for ElastiCache logging
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

resource "aws_kms_key" "cache" {
  description             = "KMS key for ElastiCache encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "cache-encryption"
  }
}

module "valkey_single_node_encrypted" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-single-cache"
  engine_version  = "8.0"
  node_type       = "cache.r7g.large"
  num_cache_nodes = 1

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  # Use default parameter group (custom groups not supported for Valkey)
  # Use null to let module create custom parameter group
  # Or set to existing default: "default.valkey8", "default.valkey9", etc.
  parameter_group_name = null
  parameter_group_family = "valkey8"
  parameters = {}

  # Security
  create_security_group = true
  security_group_ingress_rules = {
    from_app = {
      description                  = "Allow from app"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.app.id
    }
  }

  # Authentication
  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = "prod/cache/single-node-token"

  # Encryption
  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn
  transit_encryption_enabled    = true
  transit_encryption_mode       = "required"

  # Snapshots
  snapshot_retention_limit = 7
  snapshot_window          = "02:00-03:00"

  # Maintenance
  maintenance_window         = "sun:03:00-sun:04:00"
  auto_minor_version_upgrade = true

  # Logging
  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 7
  slow_log_group_name    = "/prod/single-cache/slow-log"
  engine_log_group_name  = "/prod/single-cache/engine-log"

  # Monitoring (single-node uses limited alarms)
  create_alarms       = true
  alarm_cpu_threshold = 80
  
  create_sns_topic      = true
  alert_email_addresses = ["ops@company.com"]

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    Mode        = "single-node"
  }
}

output "cache_endpoint" {
  value = module.valkey_single_node_encrypted.primary_endpoint
}

output "auth_secret_arn" {
  value = module.valkey_single_node_encrypted.auth_secret_arn
}

output "log_groups" {
  value = {
    slow_log   = module.valkey_single_node_encrypted.slow_log_group_name
    engine_log = module.valkey_single_node_encrypted.engine_log_group_name
  }
}

output "sns_topic_arn" {
  value = module.valkey_single_node_encrypted.sns_topic_arn
}
```

---

## Single-Node with Default Parameters (Recommended)

```hcl
# Note: Custom parameter groups are not supported for Valkey by AWS.
# Use default parameter groups instead. See VALKEY-PARAMETER-GROUPS.md for details.

resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "valkey_single_node_default_params" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-default-params-cache"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 1

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  # Use default parameter group (custom groups not supported for Valkey)
  # Use null to let module create custom parameter group
  # Or set to existing default: "default.valkey8", "default.valkey9", etc.
  parameter_group_name = null
  parameter_group_family = "valkey8"
  parameters = {}

  # Authentication
  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = "prod/cache/default-params-token"

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    Mode        = "single-node-default"
  }
}

output "cache_endpoint" {
  value = module.valkey_single_node_default_params.primary_endpoint
}
```

---

## Single-Node with Full Monitoring Stack

```hcl
# Create service-linked role for ElastiCache logging
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "valkey_single_node_monitored" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-monitored-cache"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 1

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  # Use null to let module create custom parameter group
  # Or set to existing default: "default.valkey8", "default.valkey9", etc.
  parameter_group_name = null
  parameter_group_family = "valkey8"
  parameters = {}

  # Security
  create_security_group = true
  security_group_ingress_rules = {
    from_app = {
      description                  = "Allow from app"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.app.id
    }
  }

  # Authentication - REQUIRES transit encryption
  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = "prod/cache/monitored-token"

  # Encryption
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  transit_encryption_mode       = "required"  # AUTH requires TLS

  # Logging
  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 30

  # Snapshots
  snapshot_retention_limit = 7
  snapshot_window          = "02:00-03:00"

  # Maintenance
  maintenance_window         = "sun:03:00-sun:04:00"
  auto_minor_version_upgrade = true

  # CloudWatch Alarms
  create_alarms               = true
  alarm_cpu_threshold         = 75
  alarm_eviction_threshold    = 1000
  alarm_connection_threshold  = 1000
  alarm_memory_threshold      = 80

  custom_alarms = {
    high_network_in = {
      metric_name         = "NetworkBytesIn"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 500000000  # 500 MB
      alarm_description   = "Network bytes in exceeds 500 MB"
    }
    high_swap_usage = {
      metric_name         = "SwapUsage"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 52428800  # 50 MB
      alarm_description   = "Swap usage exceeds 50 MB"
    }
  }

  # SNS Notifications
  create_sns_topic      = true
  alert_email_addresses = ["ops@company.com", "sre@company.com"]

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    Mode        = "single-node-monitored"
    CriticalApp = "true"
  }
}

output "cache_endpoint" {
  value = module.valkey_single_node_monitored.primary_endpoint
}

output "auth_secret_arn" {
  value = module.valkey_single_node_monitored.auth_secret_arn
}

output "log_groups" {
  value = {
    slow_log   = module.valkey_single_node_monitored.slow_log_group_name
    engine_log = module.valkey_single_node_monitored.engine_log_group_name
  }
}

output "alarm_arns" {
  value = {
    cpu         = module.valkey_single_node_monitored.alarm_cpu_utilization_arn
    evictions   = module.valkey_single_node_monitored.alarm_evictions_arn
    connections = module.valkey_single_node_monitored.alarm_connections_arn
    memory      = module.valkey_single_node_monitored.alarm_memory_usage_arn
  }
}

output "sns_topic_arn" {
  value = module.valkey_single_node_monitored.sns_topic_arn
}
```

---

## Node Type Recommendations for Single-Node

| Use Case | Recommended Node Type | Memory | vCPU |
|----------|----------------------|--------|------|
| **Development** | `cache.t4g.micro` | 0.5 GB | 2 | 
| **Small Development** | `cache.t4g.small` | 1.37 GB | 2 |
| **Staging** | `cache.t4g.medium` | 3.09 GB | 2 |
| **Small Production** | `cache.m7g.large` | 8 GB | 2 |
| **Medium Production** | `cache.r7g.large` | 16 GB | 2 |
| **Large Production** | `cache.r7g.xlarge` | 32 GB | 4 |
| **Extra Large Production** | `cache.r7g.2xlarge` | 64 GB | 8 |

---

## Important Notes for Single-Node Clusters

1. **No High Availability**: Single-node clusters have no failover capability. Maintenance and updates will cause downtime.
2. **Snapshots Available**: You can create snapshots for backup and restore operations.
3. **Parameter Groups**: Custom parameters can be configured and modified.
4. **No Multi-AZ**: Single-node clusters cannot span multiple availability zones.
5. **Limited Alarms**: Some alarms may have limited utility in single-node configurations.
6. **Suitable for**: Development, testing, staging, and non-critical workloads.

---

## Best Practices

- **Use for Development**: Single-node clusters are perfect for dev environments
- **Enable Snapshots**: Even for non-critical systems, regular snapshots are good practice
- **Monitor Memory**: Single nodes can fill up quickly; monitor evictions and memory usage
- **Plan Maintenance**: Schedule maintenance windows during low-traffic periods
- **Encryption**: Even for non-production, enable encryption for security best practices
- **Authentication**: Enable auth tokens to prevent unauthorized access, even in staging

---

## See Also

- [Parameter Group Setup](./PARAMETER-GROUP-SETUP.md) — How to configure parameter groups (3 options)
- [AUTH Token Requirement](./AUTH-TOKEN-REQUIREMENT.md) — AUTH tokens require TLS encryption
- [Valkey Parameter Groups](./VALKEY-PARAMETER-GROUPS.md) — Background on Valkey parameter group limitations
- [IAM Setup & Roles](./IAM-SETUP.md) — Required service-linked roles and Terraform permissions
- [Provisioned Multi-AZ Example](./PROVISIONED-MULTI-AZ.md)
- [Serverless Example](./SERVERLESS.md)
- [Encryption Configuration](./ENCRYPTION.md)
- [Deployment Modes](./DEPLOYMENT-MODES.md)
