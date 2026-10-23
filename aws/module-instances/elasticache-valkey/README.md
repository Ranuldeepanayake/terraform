# ElastiCache Valkey Module Instance

This directory contains a ready-to-use configuration for deploying an AWS ElastiCache Valkey cluster. It serves as an example and starting point for your infrastructure deployments.

## Overview

The module instance demonstrates how to:

- Deploy an ElastiCache Valkey cluster with configurable parameters
- Manage networking, security groups, and subnet groups
- Configure encryption, authentication, and monitoring
- Organize configuration through Terraform locals
- Export cluster connection details via outputs

## Quick Start

### Prerequisites

1. **AWS Credentials**: Ensure your AWS credentials are configured
2. **Terraform**: Version 1.0 or later installed
3. **VPC and Subnets**: An existing VPC with subnets where the cluster will be deployed
4. **Permissions**: IAM permissions to create ElastiCache resources, security groups, etc.

### Setup

1. **Update Configuration**

   Edit `main.tf` and modify the `locals` block to match your environment:

   ```hcl
   locals {
     aws_region = "ap-southeast-1"  # Change to your region
     project_name = "internal"
     cache_name = "session-cache"
     
     # Update these subnet IDs to your VPC's private subnets
     subnet_ids = [
       "subnet-xxxxxxxx",
       "subnet-yyyyyyyy"
     ]
     
     # Update to your VPC ID
     vpc_id = "vpc-zzzzzzzz"
   }
   ```

2. **Customize Cluster Parameters** (Optional)

   Modify the module block to adjust:

   - `node_type`: Choose from cache.t4g.micro, cache.m7g.large, etc.
   - `num_cache_nodes`: Single node (1) or multi-node (2+)
   - `engine_version`: Valkey version (8.0, 9.0, etc.)
   - `multi_az_enabled`: Enable for production high-availability
   - `auth_token_enabled`: Enable AUTH token for security

3. **Initialize Terraform**

   ```bash
   terraform init
   ```

4. **Plan and Apply**

   ```bash
   terraform plan    # Review changes before applying
   terraform apply   # Create the cluster
   ```

### Retrieve Connection Information

After deployment, retrieve the cluster endpoint:

```bash
terraform output primary_endpoint
terraform output connection_string
```

Use the endpoint to configure your application:

```python
# Example Python code
import redis

# Connect to ElastiCache Valkey cluster
r = redis.Redis(
    host='<cluster_address>',
    port=6379,
    decode_responses=True
)

r.set('key', 'value')
print(r.get('key'))  # Output: value
```

---

## Configuration Guide

### Basic Configuration (Development)

```hcl
# Single-node development cluster with minimal configuration
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  cluster_id     = "dev-cache"
  node_type      = "cache.t4g.micro"
  subnet_ids     = [aws_subnet.private.id]
  vpc_id         = aws_vpc.main.id
  
  tags = {
    Environment = "dev"
  }
}
```

### Production Configuration (High-Availability)

```hcl
# Multi-node production cluster with encryption and monitoring
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  cluster_id                 = "prod-cache"
  engine_version             = "8.0"
  node_type                  = "cache.m7g.large"
  num_cache_nodes            = 2
  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_ids              = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  vpc_id                  = aws_vpc.main.id
  allowed_security_groups = [aws_security_group.app_servers.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token_enabled         = true
  auth_token                 = aws_secretsmanager_secret_version.valkey_token.secret_string

  tags = {
    Environment = "production"
  }
}
```

### Custom Parameters

Configure Valkey-specific parameters:

```hcl
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  cluster_id = "custom-cache"
  
  # Customize Valkey behavior
  parameters = {
    "maxmemory-policy"      = "allkeys-lru"   # Eviction policy
    "timeout"               = "300"           # Connection timeout in seconds
    "tcp-keepalive"         = "60"            # TCP keepalive interval
    "databases"             = "16"            # Number of logical databases
  }

  subnet_ids = [aws_subnet.cache.id]
  vpc_id     = aws_vpc.main.id
}
```

---

## Key Decisions and Trade-offs

### 1. **Single-Node vs. Multi-Node**

| Aspect | Single-Node | Multi-Node + Multi-AZ |
|--------|-------------|----------------------|
| **Availability** | No failover | Automatic failover across AZs |
| **Cost** | Lower | Higher (2-3x) |
| **Snapshots** | ✓ Supported | ✗ Not supported |
| **Use Case** | Dev, non-critical cache | Production, critical data |

**Decision**: Use single-node for development/testing; multi-node for production workloads.

### 2. **Encryption**

| Setting | At-Rest | In-Transit | Production? |
|---------|---------|-----------|------------|
| None | ✗ | ✗ | Only for non-sensitive data |
| At-Rest Only | ✓ | ✗ | Limited |
| In-Transit Only | ✗ | ✓ | Limited |
| Both | ✓ | ✓ | ✓ Recommended |

**Decision**: Enable both for compliance-sensitive workloads; consider at minimum for in-transit encryption.

### 3. **Node Type Selection**

| Node Type | Memory | Use Case |
|-----------|--------|----------|
| cache.t4g.micro | 0.5 GB | Dev, testing, light load |
| cache.t4g.small | 1.37 GB | Dev caching, small apps |
| cache.m7g.large | 8 GB | General production |
| cache.m7g.xlarge | 16 GB | Heavy production load |
| cache.r7g.large | 16 GB | Memory-intensive apps |

**Decision**: Start with cache.t4g.micro for testing, cache.m7g.large for production.

### 4. **Parameter Group Strategy**

- **Shared Parameter Group**: Create once, reuse across clusters (cost-effective, version-locked)
- **Custom Parameter Group**: Fine-tune per cluster (flexible, adds management overhead)

**Decision**: Use shared for consistency; create custom only when specific tuning is needed.

---

## Outputs and Integration

After deployment, Terraform outputs provide information for consuming services:

```hcl
# Retrieve outputs after apply
primary_endpoint = elasticache_valkey.primary_endpoint
security_group_id = elasticache_valkey.security_group_id
cluster_arn = elasticache_valkey.cluster_arn
```

### Using Outputs in Other Modules

```hcl
# Example: Pass cache endpoint to Lambda environment
resource "aws_lambda_function" "app" {
  function_name = "my-app"
  environment {
    variables = {
      CACHE_ENDPOINT = module.elasticache_valkey.primary_endpoint
    }
  }
}
```

### Using Outputs in Application Code

```bash
# Store in AWS Secrets Manager
aws secretsmanager create-secret \
  --name valkey/production \
  --secret-string "$(terraform output -json primary_endpoint)"

# Retrieve in application
CACHE_ENDPOINT=$(aws secretsmanager get-secret-value \
  --secret-id valkey/production \
  --query SecretString --output text)
```

---

## Common Tasks

### 1. Scale the Cluster

To increase node count or node type:

```hcl
# In main.tf, update:
num_cache_nodes = 3        # Increase node count
node_type = "cache.m7g.xlarge"  # Upgrade node type

# Then apply changes:
terraform apply
```

### 2. Enable Authentication

```hcl
# Generate a strong token
auth_token_enabled = true
auth_token         = "your-32-128-character-token-here"

# Update in Terraform
terraform apply

# Connect with authentication
redis-cli -h <endpoint> -a <token>
```

### 3. Enable Encryption

```hcl
# Enable at-rest and in-transit encryption
at_rest_encryption_enabled = true
transit_encryption_enabled = true
transit_encryption_mode    = "required"

# Apply changes (may require replacement)
terraform apply
```

### 4. Configure Snapshots

```hcl
# Only for single-node clusters
num_cache_nodes          = 1
snapshot_retention_limit = 7  # Keep 7 days of snapshots
snapshot_window          = "03:00-05:00"

terraform apply
```

### 5. Update Engine Version

```hcl
engine_version = "9.0"  # Upgrade to new version
apply_immediately = false  # Apply during maintenance window

terraform apply
```

### 6. Delete the Cluster

To completely remove the cluster:

```bash
terraform destroy
```

---

## Monitoring and Troubleshooting

### Check Cluster Status

```bash
aws elasticache describe-cache-clusters \
  --cache-cluster-id <cluster_id> \
  --region <region>
```

### View Logs

```bash
# If CloudWatch Logs are enabled
aws logs tail /aws/elasticache/valkey/slow-log --follow
```

### Test Connectivity

```bash
# Install redis-cli (works with Valkey too)
redis-cli -h <cluster_address> -p 6379 ping

# Expected output: PONG
```

### Common Issues

| Issue | Cause | Resolution |
|-------|-------|-----------|
| **Connection refused** | Security group rule missing | Add inbound rule for port 6379 |
| **Timeout** | Wrong subnet/VPC | Verify cluster is in correct subnets |
| **AUTH failed** | Incorrect token | Verify token format and enable status |
| **High CPU** | Undersized node | Upgrade to larger node type |
| **Evictions** | Memory full | Increase num_cache_nodes or node memory |

---

## Best Practices

1. **Use Descriptive Names**: Include environment and purpose in `cluster_id`
2. **Enable Encryption**: Always encrypt at-rest and in-transit for production
3. **Multi-AZ for HA**: Use multi-node with Multi-AZ for critical applications
4. **Snapshot Retention**: Maintain 7+ days for recovery capability
5. **Monitoring**: Enable CloudWatch Logs and SNS notifications
6. **Resource Isolation**: Deploy in private subnets; restrict security groups
7. **Tag Everything**: Consistent tags enable cost allocation and governance
8. **Document**: Add comments to locals explaining team-specific decisions

---

## Files and Structure

```
elasticache-valkey/
├── main.tf           # Module instantiation and configuration locals
├── outputs.tf        # Output variable definitions
├── provider.tf       # AWS provider configuration
├── variables.tf      # Optional input variables (empty by pattern)
└── README.md         # This file
```

## Related Files

- **Module**: `../../modules/elasticache-valkey/`
- **Module Documentation**: `../../modules/elasticache-valkey/README.md`
- **VPC Configuration**: `../full-network/` (example VPC setup)

---

## Support and Contributing

For issues or questions:

1. Refer to the [ElastiCache Valkey Module Documentation](../../modules/elasticache-valkey/README.md)
2. Check [AWS ElastiCache Documentation](https://docs.aws.amazon.com/AmazonElastiCache/)
3. Review Terraform AWS Provider documentation for `aws_elasticache_cluster`

---

## License

This configuration is part of the infrastructure-as-code repository. Follow your organization's licensing and governance policies.
