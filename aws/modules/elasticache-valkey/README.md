# ElastiCache Valkey Module

This module provisions AWS ElastiCache running the Valkey engine. **Valkey is an open-source, Redis-compatible in-memory data structure store** that can be used for caching, session storage, message queues, and more.

**Why Valkey?** Valkey is the community-driven successor to Redis, maintained by the Linux Foundation. It provides long-term support and eliminates licensing concerns from Redis 7.4+. See [VALKEY-VS-REDIS.md](./documentation/VALKEY-VS-REDIS.md) for the strategic context.

The module supports two deployment modes:

- **Provisioned**: Traditional managed nodes with explicit sizing, Multi-AZ, failover, and parameter tuning
- **Serverless**: Auto-scaling capacity with no node management, built-in HA, and variable pricing

## Overview

### Provisioned Mode Creates:
- **ElastiCache Valkey Cluster**: Configurable cluster with single-node, multi-node, and Multi-AZ support
- **Subnet Group**: Organizes subnets for cluster deployment across Availability Zones
- **Security Group** (optional): Network-level access control with flexible ingress/egress rules
- **Parameter Group** (optional): Custom configuration for Valkey parameters
- **Secrets Manager Secret** (optional): Secure storage for authentication tokens
- **CloudWatch Log Groups** (optional): Automatic creation with retention policies
- **CloudWatch Alarms** (optional): Pre-built and custom alarms for monitoring
- **SNS Topic** (optional): Notifications for cluster events and alarm state changes
- **Encryption**: Support for at-rest (KMS) and in-transit (TLS) encryption
- **Authentication**: Optional AUTH token for cluster access

### Serverless Mode Creates:
- **ElastiCache Serverless Cache**: Fully managed cache with automatic scaling, no node management needed
- **Security Group** (optional): Network-level access control
- **Built-in HA**: Automatically spans multiple AZs with no configuration

The VPC and subnets must already exist; this module does not create them.

---

## Configuration Combinations

### 1. Minimal Setup (Development)

```hcl
module "valkey_dev" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "dev-cache"
  engine_version  = "8.0"
  node_type       = "cache.t4g.micro"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  create_alarms = false
  
  tags = {
    Environment = "dev"
  }
}
```

---

### 2. Authentication Options

#### 2a. With Auto-Generated Token + Secrets Manager

```hcl
resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "valkey_auth_secret" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = null  # Auto-generated: prod-cache-valkey-auth-xxxxx
}

output "auth_secret_arn" {
  value = module.valkey_auth_secret.auth_secret_arn
}
```

#### 2b. With Custom Token + Custom Secret Name

```hcl
module "valkey_custom_token" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  auth_token_enabled = true
  auth_token         = "YourCustomToken1234567890"  # 16-128 chars
  auth_secret_name   = "prod/services/cache/token"
}
```

#### 2c. Without Authentication

```hcl
module "valkey_no_auth" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "dev-cache"
  node_type       = "cache.t4g.micro"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  auth_token_enabled = false  # Default
}
```

---

### 3. Encryption Options

#### 3a. Full Encryption (At-Rest + In-Transit)

```hcl
module "valkey_full_encryption" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-secure-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result

  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn

  transit_encryption_enabled = true
  transit_encryption_mode    = "required"
}
```

#### 3b. At-Rest Only with AWS-Managed Key

```hcl
module "valkey_at_rest_only" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = null  # Uses AWS-managed key
  
  transit_encryption_enabled = false
}
```

#### 3c. No Encryption (Development Only)

```hcl
module "valkey_dev_no_encryption" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "dev-cache"
  node_type       = "cache.t4g.micro"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
}
```

---

### 4. Logging Options

#### 4a. Auto-Created Log Groups with Default Retention

```hcl
module "valkey_with_logs" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 7  # Default
}

output "slow_log_group" {
  value = module.valkey_with_logs.slow_log_group_name
}

output "engine_log_group" {
  value = module.valkey_with_logs.engine_log_group_name
}
```

#### 4b. Custom Log Group Names and Retention

```hcl
module "valkey_custom_logs" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 30

  slow_log_group_name   = "/prod/cache/slow-queries"
  engine_log_group_name = "/prod/cache/engine-events"
}
```

#### 4c. Use Existing Log Groups

```hcl
module "valkey_existing_logs" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  cloudwatch_log_enabled = true
  create_log_groups      = false

  log_delivery_configuration = {
    "slow-log" = {
      enabled                   = true
      log_format                = "json"
      cloudwatch_log_group_name = aws_cloudwatch_log_group.existing_slow.name
    }
    "engine-log" = {
      enabled                   = true
      log_format                = "json"
      cloudwatch_log_group_name = aws_cloudwatch_log_group.existing_engine.name
    }
  }
}
```

#### 4d. Logging Disabled (Development)

```hcl
module "valkey_dev_no_logs" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "dev-cache"
  node_type       = "cache.t4g.micro"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  cloudwatch_log_enabled = false  # Default
}
```

---

### 5. SNS Notifications Options

#### 5a. Module Creates SNS Topic + Email Subscriptions

```hcl
module "valkey_with_sns" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  create_sns_topic      = true
  alert_email_addresses = ["ops@company.com", "alerts@company.com"]
}

output "sns_topic_arn" {
  value = module.valkey_with_sns.sns_topic_arn
}

output "pending_confirmations" {
  value = "Email confirmations required for: ${join(", ", module.valkey_with_sns.alert_email_subscriptions)}"
}
```

#### 5b. Use Existing SNS Topic

```hcl
module "valkey_existing_sns" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  create_sns_topic       = false
  notification_topic_arn = aws_sns_topic.alerts.arn
}
```

#### 5c. No Notifications (Development)

```hcl
module "valkey_dev_no_notifications" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "dev-cache"
  node_type       = "cache.t4g.micro"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  create_sns_topic       = false
  create_alarms          = false
  notification_topic_arn = null
}
```

---

### 6. Alarm Options

#### 6a. Default Alarms Only

```hcl
module "valkey_default_alarms" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  create_alarms               = true
  alarm_cpu_threshold         = 75      # Default
  alarm_eviction_threshold    = 1000    # Default
  alarm_connection_threshold  = 1000    # Default
  alarm_memory_threshold      = 80      # Default

  create_sns_topic      = true
  alert_email_addresses = ["ops@company.com"]
}

output "alarm_arns" {
  value = {
    cpu         = module.valkey_default_alarms.alarm_cpu_utilization_arn
    evictions   = module.valkey_default_alarms.alarm_evictions_arn
    connections = module.valkey_default_alarms.alarm_connections_arn
    memory      = module.valkey_default_alarms.alarm_memory_usage_arn
    engine_cpu  = module.valkey_default_alarms.alarm_engine_cpu_arn
  }
}
```

#### 6b. Custom Thresholds

```hcl
module "valkey_custom_alarms" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  create_alarms               = true
  alarm_cpu_threshold         = 85      # More aggressive
  alarm_eviction_threshold    = 500     # More sensitive
  alarm_connection_threshold  = 500     # More sensitive
  alarm_memory_threshold      = 90      # Less headroom

  create_sns_topic      = true
  alert_email_addresses = ["ops@company.com"]
}
```

#### 6c. Default Alarms + Custom Alarms

```hcl
module "valkey_alarms_extended" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  node_type       = "cache.m7g.large"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

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
      alarm_description   = "Network bytes in exceeds 1 GB"
    }
    high_swap_usage = {
      metric_name         = "SwapUsage"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 52428800  # 50 MB
    }
  }

  create_sns_topic      = true
  alert_email_addresses = ["ops@company.com"]
}
```

#### 6d. No Alarms (Development)

```hcl
module "valkey_dev_no_alarms" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "dev-cache"
  node_type       = "cache.t4g.micro"
  subnet_ids      = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  create_alarms = false
}
```

---

### 7. Serverless Examples

#### 7a. Minimal Serverless Cache

```hcl
module "valkey_serverless_dev" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "dev-serverless-cache"
  engine_version        = "8.0"
  serverless_cache_size = 1  # 1 GB
  subnet_ids            = [aws_subnet.private.id]
  vpc_id                = aws_vpc.main.id

  tags = {
    Environment = "dev"
  }
}

output "serverless_endpoint" {
  value = module.valkey_serverless_dev.primary_endpoint
}
```

#### 7b. Serverless with Encryption

```hcl
module "valkey_serverless_encrypted" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "prod-serverless-cache"
  engine_version        = "8.0"
  serverless_cache_size = 8  # 8 GB
  subnet_ids            = [aws_subnet.private.id]
  vpc_id                = aws_vpc.main.id

  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn

  security_group_ingress_rules = {
    from_app = {
      description                  = "Allow from app"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.app.id
    }
  }

  tags = {
    Environment = "production"
  }
}
```

#### 7c. Serverless with Monitoring (SNS + Alarms not supported for serverless)

```hcl
module "valkey_serverless_monitored" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "prod-cache-serverless"
  engine_version        = "8.0"
  serverless_cache_size = 16  # 16 GB
  subnet_ids            = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  vpc_id                = aws_vpc.main.id

  at_rest_encryption_enabled = true

  security_group_ingress_rules = {
    from_app = {
      description                  = "Allow from app servers"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.app.id
    }
  }

  tags = {
    Environment = "production"
  }
}

output "serverless_cache" {
  value = {
    endpoint = module.valkey_serverless_monitored.primary_endpoint
    arn      = module.valkey_serverless_monitored.cluster_arn
  }
}
```

#### 7d. Serverless vs Provisioned Decision Matrix

| Scenario | Use Serverless | Use Provisioned |
|----------|---|---|
| **Variable/Spiky Traffic** | ✅ Yes | ❌ |
| **Predictable, Stable Traffic** | ❌ | ✅ Yes |
| **Multi-AZ Needed** | ✅ Built-in | ✅ Optional |
| **Need Custom Parameters** | ❌ | ✅ Yes |
| **Need Snapshots** | ❌ | ✅ Yes (single-node) |
| **Need Multi-Node Cluster** | ❌ | ✅ Yes |
| **Need Manual Failover Control** | ❌ | ✅ Yes |
| **Fixed, Predictable Costs** | ❌ | ✅ Yes |
| **Pay-Per-Use Pricing** | ✅ Yes | ❌ |
| **Zero Ops Setup** | ✅ Yes | ❌ |
| **CloudWatch Alarms** | ❌ Provisioned only | ✅ Yes |
| **Parameter Tuning** | ❌ AWS-managed | ✅ Yes |

---

### 8. Production-Ready: Full Provisioned Configuration

```hcl
resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "valkey_prod_provisioned" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-primary-cache"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 2
  
  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  vpc_id     = aws_vpc.main.id

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
  }

  # Authentication
  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = "prod/cache/token"

  # Encryption
  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn
  transit_encryption_enabled    = true
  transit_encryption_mode       = "required"

  # Logging
  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 30
  slow_log_group_name    = "/prod/cache/slow-log"
  engine_log_group_name  = "/prod/cache/engine-log"

  # Snapshots
  snapshot_retention_limit = 7
  snapshot_window          = "02:00-03:00"

  # Maintenance
  maintenance_window         = "sun:03:00-sun:04:00"
  auto_minor_version_upgrade = true

  # Monitoring & Alarms
  create_sns_topic      = true
  alert_email_addresses = ["ops@company.com", "sre@company.com"]

  create_alarms               = true
  alarm_cpu_threshold         = 75
  alarm_eviction_threshold    = 1000
  alarm_connection_threshold  = 1000
  alarm_memory_threshold      = 80

  custom_alarms = {
    high_network_in = {
      metric_name         = "NetworkBytesIn"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 5000000000  # 5 GB
    }
  }

  tags = {
    Environment = "production"
    CriticalApp = "true"
    Managed     = "terraform"
  }
}

output "cache_endpoint" {
  value = module.valkey_prod_provisioned.primary_endpoint
}

output "auth_secret" {
  value = module.valkey_prod_provisioned.auth_secret_arn
}

output "sns_topic" {
  value = module.valkey_prod_provisioned.sns_topic_arn
}

output "log_groups" {
  value = {
    slow_log   = module.valkey_prod_provisioned.slow_log_group_name
    engine_log = module.valkey_prod_provisioned.engine_log_group_name
  }
}
```

---

## Input Variables

### Deployment Mode

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `deployment_mode` | `string` | `"provisioned"` | Deployment mode: `"provisioned"` or `"serverless"` |

### Cluster Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cluster_id` | `string` | **required** | Unique identifier for the Valkey cluster |
| `engine_version` | `string` | `"8.0"` | Valkey engine version (e.g., `8.0`, `9.0`) |
| `node_type` | `string` | `"cache.t4g.micro"` | **Provisioned only** - Node type (compute and memory) |
| `num_cache_nodes` | `number` | `1` | **Provisioned only** - Number of cache nodes (1-500) |
| `serverless_cache_size` | `number` | `1` | **Serverless only** - Max data storage in GB (1, 2, 4, 8, 16, 32, 64, 128, 256) |

### High Availability

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `multi_az_enabled` | `bool` | `false` | **Provisioned only** - Enable Multi-AZ replication with automatic failover |
| `automatic_failover_enabled` | `bool` | `false` | **Provisioned only** - Enable automatic failover (requires 2+ nodes or Multi-AZ) |

**Note:** Serverless mode automatically spans multiple AZs with built-in HA.

### Performance and Parameters

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `parameter_group_family` | `string` | `"valkey8"` | **Provisioned only** - Parameter group family for creating custom groups (e.g., "valkey8" for Valkey 8.0, "valkey9" for 9.0) |
| `parameter_group_name` | `string` | `null` | **Provisioned only** - Existing parameter group name. If `null`, module creates custom group. See PARAMETER-GROUP-SETUP.md for details. |
| `parameters` | `map(string)` | `{}` | **Provisioned only** - Custom parameters to apply to parameter group |

**Parameter Group Setup**: AWS support for custom Valkey parameter groups is evolving. The module can create custom parameter groups, or you can reference existing ones. See [PARAMETER-GROUP-SETUP.md](./documentation/PARAMETER-GROUP-SETUP.md) for three setup options and troubleshooting.

**Note:** Serverless mode uses AWS-managed default parameters and cannot be customized.

### Networking

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `subnet_ids` | `list(string)` | **required** | Subnet IDs for cluster deployment |
| `subnet_group_name` | `string` | `null` | Custom subnet group name; if null, auto-generated |
| `port` | `number` | `6379` | Valkey port (1024-65535) |

### Security

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_security_group` | `bool` | `true` | Create a new security group for the cluster |
| `security_group_ids` | `list(string)` | `[]` | Existing security group IDs (only when `create_security_group` is false) |
| `vpc_id` | `string` | `null` | VPC ID (required when `create_security_group` is true) |
| `security_group_ingress_rules` | `map(object)` | `{}` | Ingress rules for the security group (port, protocol, source) |
| `security_group_egress_rules` | `map(object)` | `{}` | Egress rules for the security group (allows all if empty) |

### Authentication

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `auth_token_enabled` | `bool` | `false` | Enable AUTH token authentication; creates Secrets Manager secret. **Requires `transit_encryption_enabled = true`** |
| `auth_token` | `string` | `null` | Authentication token (16-128 characters, required when `auth_token_enabled` is true). **Requires transit encryption enabled.** |
| `auth_secret_name` | `string` | `null` | Custom name for Secrets Manager secret; auto-generated if not provided |

**Important:** AUTH tokens require transit encryption to be enabled. If you set `auth_token_enabled = true`, you must also set `transit_encryption_enabled = true` and `transit_encryption_mode = "required"` (or `"preferred"`). This is an AWS ElastiCache requirement.

### Encryption

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `at_rest_encryption_enabled` | `bool` | `false` | Enable encryption at rest using KMS |
| `at_rest_encryption_kms_key_id` | `string` | `null` | KMS key ARN for at-rest encryption (uses AWS-managed key if null) |
| `transit_encryption_enabled` | `bool` | `false` | **Provisioned only** - Enable TLS encryption for data in transit |
| `transit_encryption_mode` | `string` | `"preferred"` | **Provisioned only** - TLS mode: `"preferred"` or `"required"` |

### CloudWatch Logging

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cloudwatch_log_enabled` | `bool` | `false` | **Provisioned only** - Enable CloudWatch Logs for slow-log and engine-log |
| `create_log_groups` | `bool` | `true` | **Provisioned only** - Create CloudWatch log groups automatically with retention |
| `log_retention_days` | `number` | `7` | **Provisioned only** - CloudWatch log retention period in days |
| `slow_log_group_name` | `string` | `null` | **Provisioned only** - Custom log group name for slow-log; if null, auto-generated |
| `engine_log_group_name` | `string` | `null` | **Provisioned only** - Custom log group name for engine-log; if null, auto-generated |
| `log_delivery_configuration` | `map(object)` | `{}` | **Provisioned only** - Custom log delivery configuration (if provided, overrides auto-configuration) |

### Snapshots & Backups

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `snapshot_retention_limit` | `number` | `0` | **Provisioned only** - Days to retain snapshots (0-35; only for single-node clusters) |
| `snapshot_window` | `string` | `"03:00-05:00"` | **Provisioned only** - Daily snapshot window in UTC (e.g., `"03:00-05:00"`) |

### Maintenance

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `maintenance_window` | `string` | `"sun:03:00-sun:04:00"` | **Provisioned only** - Weekly maintenance window in UTC |
| `auto_minor_version_upgrade` | `bool` | `true` | **Provisioned only** - Enable automatic minor version upgrades |

### SNS Notifications

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_sns_topic` | `bool` | `false` | **Provisioned only** - Create SNS topic for alerts; if false, provide `notification_topic_arn` |
| `alert_email_addresses` | `list(string)` | `[]` | **Provisioned only** - Email addresses for alert subscriptions (only when `create_sns_topic` is true) |
| `notification_topic_arn` | `string` | `null` | **Provisioned only** - Existing SNS topic ARN (only when `create_sns_topic` is false) |

### CloudWatch Alarms

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_alarms` | `bool` | `true` | **Provisioned only** - Create CloudWatch alarms for cluster monitoring |
| `alarm_cpu_threshold` | `number` | `75` | **Provisioned only** - CPU utilization threshold (%) for alarm |
| `alarm_eviction_threshold` | `number` | `1000` | **Provisioned only** - Evictions per minute threshold for alarm |
| `alarm_connection_threshold` | `number` | `1000` | **Provisioned only** - Client connection threshold for alarm |
| `alarm_memory_threshold` | `number` | `80` | **Provisioned only** - Memory usage percentage threshold for alarm |
| `custom_alarms` | `map(object)` | `{}` | **Provisioned only** - Map of custom CloudWatch alarms to create |

### Lifecycle

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `apply_immediately` | `bool` | `false` | **Provisioned only** - Apply changes immediately (bypasses maintenance window) |
| `tags` | `map(string)` | `{}` | Tags applied to all resources created by this module |

---

## Output Variables

The module provides comprehensive outputs for all resources created. See `outputs.tf` for the complete list, including:

- **Connection**: cluster_arn, cluster_id, primary_endpoint, cluster_address, cluster_port
- **Authentication**: auth_secret_arn, auth_secret_name, auth_secret_id
- **Logging**: slow_log_group_name, engine_log_group_name
- **Alarms**: alarm_cpu_utilization_arn, alarm_evictions_arn, alarm_connections_arn, alarm_memory_usage_arn, alarm_engine_cpu_arn
- **SNS**: sns_topic_arn, sns_topic_name, alert_email_subscriptions

---

## Prerequisites

1. **VPC and Subnets**: An existing VPC with private subnets where the cluster will be deployed
2. **IAM Permissions**: See IAM Permissions section below
3. **KMS Key** (optional): If using at-rest encryption with a customer-managed key
4. **SNS Topic** (optional): If using an existing SNS topic instead of creating one

### Service-Linked Role (Required for Logging)

ElastiCache requires an **AWS service-linked role** to write logs to CloudWatch Logs. This role is automatically created by AWS on first use and requires **no manual configuration**.

**Role Name**: `AWSServiceRoleForElastiCache`

The service-linked role is created automatically when:
- You create your first ElastiCache cluster
- CloudWatch logging is enabled
- ElastiCache writes metrics to CloudWatch

**To verify the role exists**:
```bash
aws iam get-role --role-name AWSServiceRoleForElastiCache
```

If needed, you can create it explicitly:
```hcl
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}
```

See [IAM Role Examples](./documentation/IAM-SETUP.md) for complete setup patterns.

### Terraform Execution Role Permissions

Your Terraform execution role needs permissions to manage ElastiCache resources. Below are the minimum required permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ElastiCacheCluster",
      "Effect": "Allow",
      "Action": [
        "elasticache:CreateCacheCluster",
        "elasticache:CreateCacheParameterGroup",
        "elasticache:CreateServerlessCache",
        "elasticache:DeleteCacheCluster",
        "elasticache:DeleteCacheParameterGroup",
        "elasticache:DeleteServerlessCache",
        "elasticache:DescribeCacheClusters",
        "elasticache:DescribeCacheParameterGroups",
        "elasticache:DescribeServerlessCaches",
        "elasticache:ModifyCacheCluster",
        "elasticache:ModifyCacheParameterGroup",
        "elasticache:ModifyServerlessCache"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2SecurityGroups",
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/elasticache/*"
    },
    {
      "Sid": "CloudWatchAlarms",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:PutMetricAlarm"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManager",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:PutSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:*valkey*"
    },
    {
      "Sid": "SNS",
      "Effect": "Allow",
      "Action": [
        "sns:CreateTopic",
        "sns:DeleteTopic",
        "sns:SetTopicAttributes",
        "sns:Subscribe"
      ],
      "Resource": "arn:aws:sns:*:*:*elasticache*"
    },
    {
      "Sid": "KMSEncryption",
      "Effect": "Allow",
      "Action": [
        "kms:CreateGrant",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:ListAliases",
        "kms:ListGrants",
        "kms:RetireGrant"
      ],
      "Resource": "arn:aws:kms:*:*:key/*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "elasticache.*.amazonaws.com"
        }
      }
    },
    {
      "Sid": "ElastiCacheSubnetGroup",
      "Effect": "Allow",
      "Action": [
        "elasticache:CreateCacheSubnetGroup",
        "elasticache:DeleteCacheSubnetGroup",
        "elasticache:DescribeCacheSubnetGroups",
        "elasticache:ModifyCacheSubnetGroup"
      ],
      "Resource": "*"
    }
  ]
}
```

See [IAM Role Examples](./documentation/IAM-SETUP.md) for complete setup patterns with minimal, standard, and comprehensive policies.

---

## DNS Configuration

### Route53 DNS Records (Optional)

The module can automatically create Route53 CNAME records for easier DNS resolution of the ElastiCache endpoint.

**Important**: ElastiCache always creates a **private endpoint** only accessible within your VPC, regardless of DNS configuration. The Route53 record is purely for convenience; it doesn't change the security model.

Enable Route53 records:

```hcl
create_route53_record   = true
route53_zone_id         = aws_route53_zone.private.zone_id
route53_record_name     = null  # Defaults to cluster_id; set custom name if needed
```

**DNS record automatically created:**
- Record name: `caching-primary` (or your custom name)
- Type: CNAME
- Target: ElastiCache endpoint (e.g., `caching-primary.bykcyg.ng.0001.apse1.cache.amazonaws.com`)
- Accessible from: VPC only (private hosted zone)

See [Route53 DNS Documentation](./documentation/ROUTE53-DNS.md) for detailed setup and troubleshooting.

## Troubleshooting

### DNS Resolution Issues

If the Valkey endpoint is unreachable:
1. Verify the endpoint is resolvable from within your VPC
2. Check security group rules allow access on port 6379
3. Confirm the application is in the same VPC as ElastiCache
4. See [Route53 DNS Documentation](./documentation/ROUTE53-DNS.md) for DNS setup and debugging

---

## Related Resources

- [Route53 DNS Setup](./documentation/ROUTE53-DNS.md) — Fixing DNS resolution for the endpoint
- [Valkey vs Redis: Strategic Decision](./documentation/VALKEY-VS-REDIS.md) — Why Valkey and not Redis 8
- [AWS ElastiCache Documentation](https://docs.aws.amazon.com/AmazonElastiCache/)
- [Valkey Official Documentation](https://valkey.io/)
- [Linux Foundation: Valkey Project](https://www.linuxfoundation.org/projects/valkey/)
- [ElastiCache Best Practices](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/BestPractices.html)
