# Valkey Parameter Groups - Important Limitation

## Current Limitation

**AWS ElastiCache does not currently support creating custom parameter groups for Valkey.** This is a fundamental limitation of the Valkey engine support in ElastiCache as of October 2024.

### What This Means

- ❌ You **cannot** create custom parameter groups for Valkey
- ❌ You **cannot** tune individual Valkey parameters via Terraform
- ✅ You **must** use AWS-managed default parameter groups
- ✅ Default parameters work for most use cases
- ⏳ AWS may enable custom parameter groups in the future

---

## Why This Limitation Exists

AWS is still in the early stages of Valkey support in ElastiCache. Custom parameter group management is a more complex feature that requires:

1. **Parameter validation** - AWS must define valid parameter ranges for Valkey
2. **Version compatibility** - Different Valkey versions may have different parameters
3. **Testing** - AWS needs to test parameter combinations for stability
4. **API updates** - The ElastiCache API needs updates to support the feature

Redis (the predecessor) has full custom parameter group support, which took years to mature. Valkey is following a similar rollout path.

---

## Default Parameter Groups Available

Use one of these default parameter groups:

```hcl
parameter_group_name = "default.valkey8.0"   # For Valkey 8.0
parameter_group_name = "default.valkey9.0"   # For Valkey 9.0
```

The default parameter groups include:

| Parameter | Default Value | Purpose |
|-----------|---------------|---------|
| `maxmemory-policy` | `noeviction` | Eviction policy when memory is full |
| `timeout` | `0` | Client connection timeout (0 = no timeout) |
| `tcp-keepalive` | `300` | TCP keepalive in seconds |
| `databases` | `16` | Number of logical databases |
| `save` | RDB snapshots | Automatic backup frequency |

---

## Using Default Parameter Groups

### Minimal Setup

```hcl
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"

  # Use default parameter group
  parameter_group_name = "default.valkey8.0"

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  tags = {
    Environment = "production"
  }
}
```

### Important: Leave parameters Empty

```hcl
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  # ... other config ...

  parameter_group_name = "default.valkey8.0"
  parameters           = {}  # MUST be empty for Valkey
  # Do NOT set custom parameters - they are not supported
}
```

---

## Default Parameter Values

### Common Parameters in Default Group

```
maxmemory-policy = "noeviction"
  → Don't evict keys; return error when memory full
  
timeout = 0
  → No idle timeout for connections
  
tcp-keepalive = 300
  → Send TCP keepalive every 5 minutes
  
databases = 16
  → Support SELECT 0-15 commands
  
save = "900:1 300:10 60:10000"
  → RDB snapshots: 1 change in 15min, 10 in 5min, 10000 in 1min
```

---

## Workarounds for Custom Configuration Needs

If you need custom Valkey parameters, your options are:

### Option 1: Wait for AWS Support (Recommended)

Monitor AWS announcements. Custom parameter group support for Valkey will eventually be added.

### Option 2: Use Redis Instead (Short-term)

If you need custom parameters now, use Redis which already supports them:

```hcl
module "elasticache_redis" {
  source = "../../modules/elasticache-redis"  # If available
  
  engine = "redis"
  # ... supports custom parameter groups
}
```

### Option 3: Manage Parameters at Application Level

Instead of tuning ElastiCache parameters, manage behavior at the application level:

```python
# Python example
import redis

client = redis.Redis(
    host='endpoint',
    socket_keepalive=True,
    socket_keepalive_options={...},
    connection_pool_kwargs={
        'max_connections': 50,
        'socket_connect_timeout': 5,
        'socket_timeout': 5,
    }
)
```

### Option 4: Contact AWS Support

Request custom parameter group support for Valkey. AWS prioritizes features based on customer demand.

---

## Default Group vs. Custom Group Comparison

| Feature | Default Group | Custom Group |
|---------|--------------|--------------|
| **Valkey Support** | ✅ Available | ❌ Not supported |
| **Parameter Tuning** | ❌ No | ❌ N/A |
| **Maintenance** | ✅ AWS managed | ❌ N/A |
| **Performance** | ✅ Good for most workloads | ❌ N/A |
| **Flexibility** | Limited | ❌ N/A |

---

## When Default Parameters Are Sufficient

Default Valkey parameters work well for:

- **Caching**: Session stores, query caching, response caching
- **General Purpose**: Most in-memory workloads
- **Development/Testing**: All dev and test environments
- **Standard Deployments**: Most production workloads

Default parameters are **not** sufficient for:

- **Highly Optimized Workloads**: Extreme performance requirements
- **Specialized Use Cases**: Custom eviction policies
- **Complex Architectures**: Multi-tenant configurations with different policies per tenant

---

## Examples: Default Parameter Group Usage

### Single-Node with Default Parameters

```hcl
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

module "valkey_single_node" {
  source = "../../modules/elasticache-valkey"

  deployment_mode      = "provisioned"
  cluster_id           = "prod-cache"
  engine_version       = "8.0"
  node_type            = "cache.m7g.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.valkey8.0"

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
  }
}

output "cache_endpoint" {
  value = module.valkey_single_node.primary_endpoint
}
```

### Multi-AZ with Default Parameters

```hcl
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

module "valkey_multi_az" {
  source = "../../modules/elasticache-valkey"

  deployment_mode             = "provisioned"
  cluster_id                  = "prod-ha-cache"
  engine_version              = "8.0"
  node_type                   = "cache.m7g.large"
  num_cache_nodes             = 2
  multi_az_enabled            = true
  automatic_failover_enabled  = true
  parameter_group_name        = "default.valkey8.0"

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  vpc_id     = aws_vpc.main.id

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    HA          = "enabled"
  }
}

output "cache_endpoint" {
  value = module.valkey_multi_az.primary_endpoint
}
```

---

## Future: When Custom Parameters Are Supported

Once AWS enables custom parameter groups for Valkey, you'll be able to:

```hcl
# THIS WILL WORK IN THE FUTURE
module "valkey_custom" {
  source = "../../modules/elasticache-valkey"

  deployment_mode      = "provisioned"
  cluster_id           = "prod-custom-cache"
  parameter_group_name = null  # Create custom group

  parameters = {
    "maxmemory-policy"  = "volatile-lru"
    "timeout"           = "300"
    "tcp-keepalive"     = "60"
  }

  # ... rest of config
}
```

**Until then**, you must use `parameter_group_name = "default.valkey8.0"`.

---

## See Also

- [AWS ElastiCache Valkey Documentation](https://docs.aws.amazon.com/AmazonElastiCache/)
- [Valkey Official Documentation](https://valkey.io/)
- [PROVISIONED-SINGLE-INSTANCE.md](./PROVISIONED-SINGLE-INSTANCE.md)
- [PROVISIONED-MULTI-AZ.md](./PROVISIONED-MULTI-AZ.md)
