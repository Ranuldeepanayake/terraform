# Valkey Parameter Group Setup

## Current Status

AWS ElastiCache Valkey support is still evolving. Parameter group handling depends on your region and AWS account setup.

---

## Three Options

### How It Works

The module has conditional logic:

```hcl
# When parameter_group_name = null:
#   ✅ Creates custom parameter group
#   ✅ Uses parameter_group_family to set family
#   ✅ Applies custom parameters
#
# When parameter_group_name = "existing-group":
#   ✅ Uses existing parameter group
#   ❌ Ignores parameter_group_family (not needed)
#   ❌ Ignores parameters variable (not applied)
```

---

### Option 1: Let Module Create Custom Parameter Group (Recommended)

```hcl
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  # ... other config ...

  # Leave these unset to let module create custom group
  parameter_group_name = null
  parameter_group_family = "valkey"
  parameters = {}
}
```

**What happens**: The module creates a parameter group named `{cluster_id}-{random_suffix}` with default Valkey settings.

**Pros**:
- Automatic
- Tailored to your cluster
- Easy to manage

**Cons**:
- May fail if AWS API doesn't support creating custom Valkey groups in your region

### Option 2: Use Existing Default Parameter Group

If a default parameter group exists in your region:

```hcl
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  # ... other config ...

  parameter_group_name = "default.valkey8"  # Use existing default
  # When parameter_group_name is set, parameter_group_family is IGNORED
  # (you don't need to set it, but it won't cause an error)
}
```

**Important**: When `parameter_group_name` is set to an existing group, the `parameter_group_family` variable is **completely ignored** by the module. The existing group is used as-is.

**Finding the correct name**: Default parameter group names vary by region/AWS account:
- `default.valkey8` ✅ (common)
- `default.valkey8.0`
- `default.valkey9`
- `default.valkey9.0`
- `valkey8`
- `valkey9`

**Try these in order**:
1. `default.valkey8` (most common)
2. `default.valkey9` (if Valkey 9.0+)
3. `default.valkey8.0` (region-specific)
4. `valkey8` (alternative naming)

**To find available parameter groups** (requires `elasticache:DescribeCacheParameterGroups` permission):

```bash
aws elasticache describe-cache-parameter-groups \
  --region your-region \
  --query 'ParameterGroups[?contains(CacheParameterGroupName, `valkey`)].CacheParameterGroupName' \
  --output table
```

### Option 3: Create Parameter Group Manually First

If Options 1 and 2 fail, create the parameter group explicitly:

```hcl
resource "aws_elasticache_parameter_group" "valkey" {
  family      = "valkey"
  name        = "custom-valkey-params"
  description = "Custom Valkey parameters"
  
  # Optional: customize parameters
  # parameter {
  #   name  = "maxmemory-policy"
  #   value = "allkeys-lru"
  # }

  tags = {
    Environment = "production"
  }
}

module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  # ... other config ...

  parameter_group_name = aws_elasticache_parameter_group.valkey.name
}
```

---

## Recommended Configuration by Scenario

### Production - Full Encryption with Custom Group

```hcl
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

# Option A: Let module create parameter group
module "valkey_prod" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 2

  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  vpc_id     = aws_vpc.main.id

  # Let module create parameter group
  parameter_group_name   = null
  parameter_group_family = "valkey8"  # For Valkey 8.0; use "valkey9" for 9.0
  parameters             = {}

  # Authentication
  auth_token_enabled = true
  auth_token         = random_password.auth.result
  auth_secret_name   = "prod/cache/token"

  # Encryption
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"
  at_rest_encryption_enabled = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
  }
}
```

### Staging - Minimal with Default Group

```hcl
module "valkey_staging" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "staging-cache"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 1

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  # Use default parameter group (name varies by region)
  # Try: default.valkey8, default.valkey9, default.valkey8.0
  # If none exist, set parameter_group_name = null
  parameter_group_name = "default.valkey8"

  auth_token_enabled = true
  auth_token         = random_password.auth.result
  
  transit_encryption_enabled = true
  transit_encryption_mode    = "preferred"

  tags = {
    Environment = "staging"
  }
}
```

### Development - Minimal Setup

```hcl
module "valkey_dev" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "dev-cache"
  engine_version  = "8.0"
  node_type       = "cache.t4g.micro"

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  # Let module create parameter group
  parameter_group_name   = null
  parameter_group_family = "valkey8"  # For Valkey 8.0; use "valkey9" for 9.0
  parameters             = {}

  auth_token_enabled         = false
  transit_encryption_enabled = false

  tags = {
    Environment = "development"
  }
}
```

---

## Troubleshooting

### Error: CacheParameterGroupNotFound

**Message**: `CacheParameterGroup not found: default.valkey8.0`

**Cause**: The parameter group name doesn't exist in your region (names vary).

**Solution**: 
1. Try alternative names:
   - `default.valkey8` ✅ (try this first)
   - `default.valkey9`
   - `default.valkey8.0`
   - `valkey8`
2. If none exist, set `parameter_group_name = null` to let module create one
3. Or manually create a parameter group first (Option 3)

### Error: CreateCacheParameterGroup API not supported

**Message**: `CreateCacheParameterGroup operation is not supported for Valkey`

**Cause**: Your region doesn't support creating custom Valkey parameter groups yet.

**Solution**:
1. Wait for AWS to enable the feature in your region
2. Try a different region
3. Contact AWS support to enable the feature

### Error: Family "valkey" is not valid

**Message**: `Family valkey is not a valid parameter group family`

**Cause**: The parameter group family name is wrong.

**Solution**: Try these alternative names:
```hcl
parameter_group_family = "valkey"      # Try this first
parameter_group_family = "valkey8.0"   # Or this
parameter_group_family = "redis7"      # Or fall back to Redis
```

---

## Best Practices

1. **Start with Option 1** (module creates group) — simplest and most flexible
2. **Use default groups only if they exist** — reduces failures
3. **Store parameter group names in variables** — easier to manage across environments
4. **Document your choice** — add comments explaining why you chose your approach
5. **Test in staging first** — verify parameter group creation works before production

---

## AWS Documentation

- [ElastiCache Parameter Groups](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/ParameterGroups.html)
- [Valkey on ElastiCache](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/supported-engine-versions.html#valkey)
- [Creating Parameter Groups](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/ParameterGroups.Creating.html)
