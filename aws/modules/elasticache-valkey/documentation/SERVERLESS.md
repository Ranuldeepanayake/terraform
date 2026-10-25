# Serverless Example

This example demonstrates how to deploy an ElastiCache Valkey cluster in **serverless mode**. Serverless caches provide fully managed, auto-scaling capacity with built-in high availability and minimal operational overhead.

## Key Characteristics

- **Fully Managed**: No node management or sizing required
- **Auto-Scaling**: Capacity automatically scales with demand
- **Built-in HA**: Automatically spans multiple AZs with no configuration
- **Pay-Per-Use**: Variable pricing based on actual usage
- **Minimal Ops**: AWS handles all infrastructure management
- **Use Case**: Variable/spiky traffic, development, microservices

---

## Minimal Serverless Setup

```hcl
module "valkey_serverless" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "dev-serverless-cache"
  engine_version        = "8.0"
  serverless_cache_size = 1  # 1 GB

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  tags = {
    Environment = "dev"
  }
}

output "cache_endpoint" {
  value = module.valkey_serverless.primary_endpoint
}
```

---

## Serverless with Basic Security

```hcl
module "valkey_serverless_secure" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "staging-serverless-cache"
  engine_version        = "8.0"
  serverless_cache_size = 4  # 4 GB

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  # Security Group
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

  tags = {
    Environment = "staging"
  }
}

output "cache_endpoint" {
  value = module.valkey_serverless_secure.primary_endpoint
}

output "security_group_id" {
  value = module.valkey_serverless_secure.security_group_id
}
```

---

## Serverless with Encryption

```hcl
# Create service-linked role for ElastiCache operations
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "aws_kms_key" "cache" {
  description             = "KMS key for serverless ElastiCache encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "serverless-cache-encryption"
  }
}

module "valkey_serverless_encrypted" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "prod-serverless-cache"
  engine_version        = "8.0"
  serverless_cache_size = 8  # 8 GB

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  vpc_id = aws_vpc.main.id

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

  # Encryption (At-Rest Only - Serverless doesn't support in-transit encryption config)
  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    Encryption  = "enabled"
  }
}

output "cache_endpoint" {
  value = module.valkey_serverless_encrypted.primary_endpoint
}

output "cache_address" {
  value = module.valkey_serverless_encrypted.cluster_address
}

output "cache_arn" {
  value = module.valkey_serverless_encrypted.cluster_arn
}
```

---

## Small Serverless Cache for Microservices

```hcl
module "valkey_serverless_microservice" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "microservice-cache"
  engine_version        = "8.0"
  serverless_cache_size = 2  # 2 GB (good for session store)

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  vpc_id = aws_vpc.main.id

  # Security - allow from microservice security group
  create_security_group = true
  security_group_ingress_rules = {
    from_microservices = {
      description                  = "Allow from microservices"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.microservices.id
    }
  }

  # Encryption
  at_rest_encryption_enabled = true

  tags = {
    Environment = "production"
    Application = "microservices"
    UseCase     = "session-store"
  }
}

output "cache_endpoint" {
  value = module.valkey_serverless_microservice.primary_endpoint
}
```

---

## Medium Serverless Cache for APIs

```hcl
resource "aws_kms_key" "cache" {
  description             = "KMS key for API cache"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

module "valkey_serverless_api_cache" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "api-cache"
  engine_version        = "8.0"
  serverless_cache_size = 16  # 16 GB for API caching

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id
  ]
  vpc_id = aws_vpc.main.id

  # Security - multiple sources
  create_security_group = true
  security_group_ingress_rules = {
    from_api_servers = {
      description                  = "Allow from API servers"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.api.id
    }
    from_backends = {
      description                  = "Allow from backend services"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.backend.id
    }
  }

  # Encryption
  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn

  tags = {
    Environment = "production"
    Application = "api"
    UseCase     = "response-cache"
  }
}

output "cache_endpoint" {
  value = module.valkey_serverless_api_cache.primary_endpoint
}

output "cache_dns" {
  value = module.valkey_serverless_api_cache.cluster_address
}
```

---

## Large Serverless Cache for High-Traffic Workload

```hcl
# Create service-linked role for ElastiCache operations
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "aws_kms_key" "cache" {
  description             = "KMS key for high-traffic cache"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "high-traffic-cache"
  }
}

module "valkey_serverless_high_traffic" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "high-traffic-cache"
  engine_version        = "8.0"
  serverless_cache_size = 64  # 64 GB for high-traffic

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id
  ]
  vpc_id = aws_vpc.main.id

  # Security - comprehensive access control
  create_security_group = true
  security_group_ingress_rules = {
    from_web_servers = {
      description                  = "Allow from web servers"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.web.id
    }
    from_app_servers = {
      description                  = "Allow from app servers"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.app.id
    }
    from_worker_nodes = {
      description                  = "Allow from worker nodes"
      from_port                    = 6379
      to_port                      = 6379
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.workers.id
    }
  }

  # Full Encryption
  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    Application = "main-platform"
    UseCase     = "session-and-cache"
    CriticalApp = "true"
  }
}

output "cache_endpoint" {
  value = module.valkey_serverless_high_traffic.primary_endpoint
}

output "cache_address" {
  value = module.valkey_serverless_high_traffic.cluster_address
}

output "cache_port" {
  value = module.valkey_serverless_high_traffic.cluster_port
}

output "cache_arn" {
  value = module.valkey_serverless_high_traffic.cluster_arn
}
```

---

## Development Serverless Cache (Minimal Setup)

```hcl
module "valkey_serverless_dev" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "dev-cache"
  engine_version        = "8.0"
  serverless_cache_size = 1  # 1 GB (smallest option)

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  # Basic security
  create_security_group = true
  security_group_ingress_rules = {
    from_dev = {
      description = "Allow from dev environment"
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_ipv4   = "10.0.0.0/8"  # Internal network
    }
  }

  # No encryption for dev (cost optimization)
  at_rest_encryption_enabled = false

  tags = {
    Environment = "development"
    Temporary   = "false"
  }
}

output "cache_endpoint" {
  value = module.valkey_serverless_dev.primary_endpoint
}
```

---

## Serverless Capacity Sizing Guide

| Size | Use Case | Estimated Cost/Month |
|------|----------|----------------------|
| **1 GB** | Development, testing | ~$0-5 |
| **2 GB** | Session store for small apps | ~$5-15 |
| **4 GB** | API caching for medium apps | ~$15-30 |
| **8 GB** | API caching for larger apps | ~$30-60 |
| **16 GB** | High-traffic API caching | ~$60-120 |
| **32 GB** | Very high-traffic workloads | ~$120-250 |
| **64 GB** | Maximum capacity available | ~$250-500+ |
| **128+ GB** | Consider provisioned for better pricing | Variable |
| **256 GB** | Maximum capacity available | Variable |

*Costs are approximate and depend on AWS region and actual read/write operations*

---

## Serverless vs. Provisioned Decision Matrix

| Factor | Serverless | Provisioned |
|--------|-----------|------------|
| **Scaling** | Automatic | Manual |
| **Setup Complexity** | Simple | More complex |
| **HA/Multi-AZ** | Built-in | Optional |
| **Cost Predictability** | Variable | Fixed |
| **Best For** | Variable traffic | Stable traffic |
| **Maintenance** | None | Scheduled |
| **Custom Parameters** | No | Yes |
| **Snapshots** | Automatic backup | Optional |
| **Auth Tokens** | Not supported | Supported |
| **Logging** | Not available | Available |
| **CloudWatch Alarms** | Limited | Full support |

---

## Important Notes for Serverless

1. **No Authentication Tokens**: Serverless doesn't support AUTH token mode
2. **AWS-Managed Parameters**: Cannot customize Valkey parameters
3. **No Transit Encryption Control**: TLS is always enabled
4. **No Snapshots Config**: AWS manages backups automatically
5. **Automatic HA**: Multi-AZ is always enabled
6. **Capacity Changes**: Scale up/down via `serverless_cache_size` variable
7. **Pay-Per-Use**: Billed for reads/writes + data storage
8. **No Cluster Mode**: Single shard only (no multi-shard distributed cache)

---

## Best Practices for Serverless

- **Start Small**: Begin with 1-2 GB and scale based on actual usage
- **Enable Encryption**: Always enable at-rest encryption for production
- **Monitor Usage**: Check CloudWatch metrics to right-size capacity
- **Use VPC**: Deploy in VPC with proper security groups
- **Multiple Subnets**: Specify subnets in different AZs for resilience
- **Cost Monitoring**: Set up CloudWatch alarms for unexpected usage spikes
- **Connection Pooling**: Use connection pooling in client applications
- **Failover Resilience**: Ensure applications handle temporary disruptions gracefully

---

## Capacity Scaling Example

```hcl
# Start with small cache
module "valkey_serverless" {
  source = "../../modules/elasticache-valkey"

  deployment_mode       = "serverless"
  cluster_id            = "app-cache"
  serverless_cache_size = 4  # Start with 4 GB

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  vpc_id     = aws_vpc.main.id

  at_rest_encryption_enabled = true

  tags = {
    Environment = "production"
  }
}

# When usage grows, simply update the variable
# (Change serverless_cache_size to 8, 16, 32, etc.)
# Apply terraform plan and see cost impact before implementing
```

---

## Monitoring Serverless Performance

Create a dashboard to monitor serverless cache:

```hcl
resource "aws_cloudwatch_dashboard" "cache" {
  dashboard_name = "serverless-cache-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CacheHits", { stat = "Sum" }],
            [".", "CacheMisses", { stat = "Sum" }],
            [".", "BytesReadIntoMemcached", { stat = "Average" }],
            [".", "BytesWrittenOutFromMemcached", { stat = "Average" }],
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Cache Performance"
        }
      }
    ]
  })
}
```

---

## See Also

- [IAM Setup & Roles](./IAM-SETUP.md) — Required service-linked roles and Terraform permissions
- [Provisioned Single-Instance Example](./PROVISIONED-SINGLE-INSTANCE.md)
- [Provisioned Multi-AZ Example](./PROVISIONED-MULTI-AZ.md)
- [Encryption Configuration](./ENCRYPTION.md)
- [Deployment Modes](./DEPLOYMENT-MODES.md)
