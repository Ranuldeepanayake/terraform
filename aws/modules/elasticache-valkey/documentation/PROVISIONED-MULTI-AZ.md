# Provisioned Multi-AZ Example

This example demonstrates how to deploy an ElastiCache Valkey cluster in **provisioned mode with Multi-AZ replication**. Multi-AZ clusters provide high availability, automatic failover, and data redundancy across multiple availability zones.

## Key Characteristics

- **Multi-Node Replication**: Primary + Replica nodes in different AZs
- **Automatic Failover**: Seamless failover to replica if primary fails
- **Zero-Downtime Maintenance**: Updates can be applied without user impact
- **High Availability**: Spans 2 or more availability zones
- **Cost**: Higher than single-node, but provides HA
- **Use Case**: Production workloads requiring high availability

---

## Minimal Multi-AZ Setup

```hcl
module "valkey_multi_az" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache-ha"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 2

  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  vpc_id = aws_vpc.main.id

  tags = {
    Environment = "production"
    HA          = "enabled"
  }
}

output "cache_endpoint" {
  value = module.valkey_multi_az.primary_endpoint
}

output "cache_arn" {
  value = module.valkey_multi_az.cluster_arn
}
```

---

## Multi-AZ with Basic Security & Authentication (AUTH + TLS)

```hcl
# AUTH tokens REQUIRE transit encryption - they cannot be used without TLS
resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "valkey_multi_az_secure" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-secure-cache-ha"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 2

  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  vpc_id = aws_vpc.main.id

  # Use null to let module create custom parameter group
  # Or set to existing default: "default.valkey8", "default.valkey9", etc.
  parameter_group_name = null
  parameter_group_family = "valkey8"
  parameters = {}

  # Security Group
  create_security_group = true
  security_group_ingress_rules = {
    from_app_servers = {
      description                  = "Allow from app servers"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.app.id
    }
    from_workers = {
      description                  = "Allow from worker nodes"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.workers.id
    }
  }

  # Authentication - REQUIRES transit encryption
  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = "prod/cache/ha-token"

  # Transit Encryption - REQUIRED for AUTH tokens
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"

  tags = {
    Environment = "production"
    HA          = "enabled"
  }
}

output "cache_endpoint" {
  value = module.valkey_multi_az_secure.primary_endpoint
}

output "auth_secret_arn" {
  value = module.valkey_multi_az_secure.auth_secret_arn
}
```

---

## Multi-AZ with Full Encryption (At-Rest + In-Transit)

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
  description             = "KMS key for ElastiCache Multi-AZ encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "cache-encryption"
  }
}

resource "aws_kms_alias" "cache" {
  name          = "alias/elasticache-valkey"
  target_key_id = aws_kms_key.cache.key_id
}

module "valkey_multi_az_encrypted" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-encrypted-cache-ha"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 2

  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  vpc_id = aws_vpc.main.id

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

  # Authentication
  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = "prod/cache/encrypted-ha-token"

  # Full Encryption (At-Rest + In-Transit)
  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn
  
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"  # Enforce TLS

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    HA          = "enabled"
    Encryption  = "full"
  }
}

output "cache_endpoint" {
  value = module.valkey_multi_az_encrypted.primary_endpoint
}

output "auth_secret_arn" {
  value = module.valkey_multi_az_encrypted.auth_secret_arn
}

output "kms_key_id" {
  value = aws_kms_key.cache.id
}
```

---

## Multi-AZ with Logging & Snapshots

```hcl
# Create service-linked role for ElastiCache logging
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "valkey_multi_az_with_logs" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-logged-cache-ha"
  engine_version  = "8.0"
  node_type       = "cache.r7g.large"
  num_cache_nodes = 2

  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  vpc_id = aws_vpc.main.id

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
  auth_secret_name   = "prod/cache/logged-ha-token"

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"

  # CloudWatch Logging
  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 30
  slow_log_group_name    = "/prod/cache-ha/slow-log"
  engine_log_group_name  = "/prod/cache-ha/engine-log"

  # Snapshots (Multi-AZ doesn't support snapshots in cluster mode, but single-node does)
  # snapshot_retention_limit = 7
  # snapshot_window          = "02:00-03:00"

  # Maintenance
  maintenance_window         = "sun:03:00-sun:04:00"
  auto_minor_version_upgrade = true

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    HA          = "enabled"
    Logging     = "enabled"
  }
}

output "cache_endpoint" {
  value = module.valkey_multi_az_with_logs.primary_endpoint
}

output "log_groups" {
  value = {
    slow_log   = module.valkey_multi_az_with_logs.slow_log_group_name
    engine_log = module.valkey_multi_az_with_logs.engine_log_group_name
  }
}
```

---

## Multi-AZ with Complete Monitoring & Alerting

```hcl
# Create service-linked role for ElastiCache logging
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "valkey_multi_az_monitored" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-monitored-cache-ha"
  engine_version  = "8.0"
  node_type       = "cache.r7g.large"
  num_cache_nodes = 2

  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  vpc_id = aws_vpc.main.id

  # Use null to let module create custom parameter group
  # Or set to existing default: "default.valkey8", "default.valkey9", etc.
  parameter_group_name = null
  parameter_group_family = "valkey8"
  parameters = {}

  # Security
  create_security_group = true
  security_group_ingress_rules = {
    from_app_servers = {
      description                  = "Allow from app servers"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.app.id
    }
    from_internal_services = {
      description                  = "Allow from internal services"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.internal.id
    }
  }

  # Authentication - REQUIRES transit encryption
  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = "prod/cache/monitored-ha-token"

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"  # AUTH requires TLS

  # CloudWatch Logging
  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 30

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
      threshold           = 1000000000  # 1 GB
      alarm_description   = "High network traffic detected"
    }
    high_network_out = {
      metric_name         = "NetworkBytesOut"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 1000000000  # 1 GB
      alarm_description   = "High network output detected"
    }
    replication_lag = {
      metric_name         = "ReplicationLag"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 5  # seconds
      alarm_description   = "Replica lag is high"
    }
  }

  # SNS Notifications
  create_sns_topic      = true
  alert_email_addresses = [
    "ops@company.com",
    "sre@company.com",
    "infrastructure@company.com"
  ]

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    HA          = "enabled"
    CriticalApp = "true"
    Monitoring  = "comprehensive"
  }
}

output "cache_endpoint" {
  value = module.valkey_multi_az_monitored.primary_endpoint
}

output "auth_secret_arn" {
  value = module.valkey_multi_az_monitored.auth_secret_arn
}

output "log_groups" {
  value = {
    slow_log   = module.valkey_multi_az_monitored.slow_log_group_name
    engine_log = module.valkey_multi_az_monitored.engine_log_group_name
  }
}

output "alarm_arns" {
  value = {
    cpu         = module.valkey_multi_az_monitored.alarm_cpu_utilization_arn
    evictions   = module.valkey_multi_az_monitored.alarm_evictions_arn
    connections = module.valkey_multi_az_monitored.alarm_connections_arn
    memory      = module.valkey_multi_az_monitored.alarm_memory_usage_arn
    engine_cpu  = module.valkey_multi_az_monitored.alarm_engine_cpu_arn
  }
}

output "sns_topic_arn" {
  value = module.valkey_multi_az_monitored.sns_topic_arn
}

output "alert_subscriptions" {
  value = module.valkey_multi_az_monitored.alert_email_subscriptions
}
```

---

## Multi-AZ with Default Parameters (Recommended)

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

module "valkey_multi_az_default_params" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-default-cache-ha"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 2

  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  vpc_id = aws_vpc.main.id

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
  auth_secret_name   = "prod/cache/default-params-ha-token"

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    HA          = "enabled"
  }
}

output "cache_endpoint" {
  value = module.valkey_multi_az_default_params.primary_endpoint
}
```

---

## Node Type Recommendations for Multi-AZ

| Scale | Recommended Node Type | Memory | vCPU | Suitable For |
|-------|----------------------|--------|------|--------------|
| **Small HA** | `cache.m7g.large` | 8 GB | 2 | Small production workloads |
| **Medium HA** | `cache.r7g.large` | 16 GB | 2 | Medium production workloads |
| **Large HA** | `cache.r7g.xlarge` | 32 GB | 4 | Large production workloads |
| **Extra Large HA** | `cache.r7g.2xlarge` | 64 GB | 8 | High-traffic production |
| **Maximum HA** | `cache.r7g.4xlarge` | 128 GB | 16 | Very high-traffic production |

---

## Important Notes for Multi-AZ Clusters

1. **Automatic Failover**: When enabled, failed primaries are automatically replaced with replicas
2. **Zero-Downtime Updates**: Maintenance windows apply updates without downtime
3. **Replication Lag**: Keep monitoring replication lag to detect issues
4. **Snapshot Limitations**: Multi-node clusters don't support snapshots (single-node only)
5. **Network Costs**: Data replication across AZs incurs cross-AZ data transfer costs
6. **Minimum 2 Nodes**: Multi-AZ requires at least 2 nodes (primary + replica)
7. **Preferred AZ**: You can configure which AZ gets the primary node

---

## Best Practices for Multi-AZ

- **Use for Production**: Multi-AZ is recommended for all production workloads
- **Enable Encryption**: Always use full encryption (at-rest + in-transit)
- **Setup Monitoring**: Configure CloudWatch alarms for comprehensive monitoring
- **Enable Logging**: Enable slow-log and engine-log for troubleshooting
- **Plan Capacity**: Account for network costs of cross-AZ replication
- **Regular Maintenance**: Schedule maintenance during off-peak hours
- **Test Failover**: Periodically verify automatic failover works as expected
- **Use Secrets Manager**: Store authentication tokens securely in Secrets Manager

---

## Multi-AZ Failover Process

When a primary node fails:

1. ElastiCache detects the failure
2. Automatic failover is triggered (if enabled)
3. Replica is promoted to primary
4. Connection attempts are redirected to the new primary
5. Original primary is replaced when available
6. Cluster returns to healthy state

**Failover typically completes in 30-60 seconds**, with minimal impact if auto-reconnection is configured on the client side.

---

## See Also

- [Parameter Group Setup](./PARAMETER-GROUP-SETUP.md) — How to configure parameter groups (3 options)
- [AUTH Token Requirement](./AUTH-TOKEN-REQUIREMENT.md) — AUTH tokens require TLS encryption
- [Valkey Parameter Groups](./VALKEY-PARAMETER-GROUPS.md) — Background on Valkey parameter group limitations
- [IAM Setup & Roles](./IAM-SETUP.md) — Required service-linked roles and Terraform permissions
- [Provisioned Single-Instance Example](./PROVISIONED-SINGLE-INSTANCE.md)
- [Serverless Example](./SERVERLESS.md)
- [Encryption Configuration](./ENCRYPTION.md)
- [Deployment Modes](./DEPLOYMENT-MODES.md)
