# ElastiCache Valkey Module Examples

This directory contains comprehensive example configurations for both deployment modes of the ElastiCache Valkey module.

## Files

### `provisioned.tf`

**Complete provisioned mode example with all available options.**

This file demonstrates every configurable parameter for provisioned deployment mode, including:
- Multi-node setup with Multi-AZ and automatic failover
- Authentication with auto-generated tokens and Secrets Manager
- Full encryption (at-rest and in-transit)
- CloudWatch logging with custom retention
- Automatic snapshots
- SNS notifications with email subscriptions
- Pre-built and custom CloudWatch alarms
- Security group rules (from security groups and CIDR blocks)
- Custom parameters and maintenance windows

**Use this example when:**
- You need production-grade multi-node clusters
- You want full control over HA, failover, and monitoring
- Your workload has predictable, stable traffic
- You need custom parameter tuning
- You require snapshots for disaster recovery

### `serverless.tf`

**Complete serverless mode example with all available options.**

This file demonstrates every configurable parameter for serverless deployment mode, including:
- Serverless auto-scaling capacity
- At-rest encryption (note: transit encryption not available in serverless)
- Security group configuration
- Built-in Multi-AZ HA (automatic, no configuration needed)
- Detailed notes on limitations and best practices

**Use this example when:**
- Your workload has variable or spiky traffic patterns
- You want zero operational overhead
- You prefer pay-per-use pricing
- You need automatic failover and backups
- You don't require custom parameter tuning or snapshots

## Key Differences

| Feature | Provisioned | Serverless |
|---------|------------|-----------|
| Node Management | Manual sizing | Automatic scaling |
| Multi-AZ | Optional (configurable) | Built-in (always enabled) |
| Failover | Optional automatic failover | Always enabled |
| Capacity Planning | Fixed cost | Pay-per-use |
| Authentication Tokens | ✅ Supported | ❌ Not supported |
| CloudWatch Logs | ✅ Supported | ❌ Not supported |
| CloudWatch Alarms | ✅ Supported | ❌ Not supported |
| Custom Parameters | ✅ Supported | ❌ Not supported |
| Snapshots | ✅ Supported (single-node) | ❌ Not supported |
| Transit Encryption | ✅ Supported | ❌ Not available |

## Configuration Checklists

### Provisioned Mode Configuration Checklist

**Required:**
- [ ] `deployment_mode = "provisioned"`
- [ ] `cluster_id`
- [ ] `subnet_ids`
- [ ] `vpc_id` (if creating security group)

**High Availability:**
- [ ] Set `node_type` appropriately (t4g for dev, m7g/r7g for prod)
- [ ] Set `num_cache_nodes` (1 for single-node, 2+ for HA)
- [ ] Set `multi_az_enabled = true` for production
- [ ] Set `automatic_failover_enabled = true` if using Multi-AZ or 2+ nodes

**Security:**
- [ ] Configure `security_group_ingress_rules` for access control
- [ ] Set `auth_token_enabled = true` for production
- [ ] Set `at_rest_encryption_enabled = true` for sensitive data
- [ ] Set `transit_encryption_enabled = true` if using auth tokens

**Monitoring:**
- [ ] Set `cloudwatch_log_enabled = true` for troubleshooting
- [ ] Set `create_sns_topic = true` or provide `notification_topic_arn`
- [ ] Set `create_alarms = true` and configure thresholds
- [ ] Provide `alert_email_addresses` for notifications

**Backups & Maintenance:**
- [ ] Set `snapshot_retention_limit` > 0 for single-node backup
- [ ] Configure `maintenance_window` for off-peak time
- [ ] Set `auto_minor_version_upgrade = true` for security patches

### Serverless Mode Configuration Checklist

**Required:**
- [ ] `deployment_mode = "serverless"`
- [ ] `cluster_id`
- [ ] `serverless_cache_size` (start small: 1-4 GB)
- [ ] `subnet_ids` (at least 1, serverless handles Multi-AZ)
- [ ] `vpc_id` (if creating security group)

**Security:**
- [ ] Configure `security_group_ingress_rules` for access control
- [ ] Set `at_rest_encryption_enabled = true` for sensitive data
- [ ] Note: No auth tokens, no transit encryption in serverless

**Monitoring:**
- [ ] Remember: CloudWatch Logs/Alarms/SNS are provisioned-only
- [ ] Monitor via CloudWatch metrics (NetworkBytesIn, CommandsPerSecond, etc.)
- [ ] Track actual data usage to right-size capacity

**Capacity Planning:**
- [ ] Monitor CloudWatch `DatabaseMemoryUsagePercentage`
- [ ] Scale up `serverless_cache_size` if approaching limits
- [ ] Remember: Serverless auto-scales, but max is your configured size

## Best Practices

### Provisioned Mode

1. **Start with development sizing** (t4g.micro) and test before production
2. **Always use Multi-AZ for production** with automatic failover
3. **Enable encryption** for sensitive workloads (at-rest + transit)
4. **Configure alarms early** to catch issues before they impact users
5. **Use custom parameters sparingly** - defaults work for most workloads
6. **Enable snapshots for single-node** if data loss is unacceptable
7. **Monitor CloudWatch metrics** regularly

### Serverless Mode

1. **Start with 1-2 GB capacity** and scale up based on actual usage
2. **Monitor CloudWatch metrics** closely initially to validate sizing
3. **Encryption is optional but recommended** for sensitive data
4. **Security groups are still required** - don't skip network controls
5. **No auth tokens available** - rely on network-level security
6. **Understand the cost model** - calculate TCO vs provisioned
7. **Use for workloads with unpredictable patterns**

## Testing Your Configuration

### 1. Syntax Validation
```bash
terraform init
terraform validate
```

### 2. Plan Review
```bash
terraform plan -out=tfplan
```

### 3. Check Outputs
Review the planned outputs to ensure you're getting:
- Correct endpoint
- Secret ARN (if auth enabled)
- Log group names
- Alarm ARNs (provisioned only)
- SNS topic ARN

### 4. Apply
```bash
terraform apply tfplan
```

### 5. Verify Connectivity
```bash
# Get the endpoint
ENDPOINT=$(terraform output -raw endpoint)

# Test connection (requires redis-cli installed)
redis-cli -h $ENDPOINT ping

# Or if auth is enabled:
AUTH_TOKEN=$(aws secretsmanager get-secret-value --secret-id <secret-name> --query SecretString --output text)
redis-cli -h $ENDPOINT -a $AUTH_TOKEN ping
```

## Modifying Existing Deployments

### Scaling Up (Provisioned)
```hcl
# Increase node count or node type
num_cache_nodes = 3  # Was 2
# OR
node_type = "cache.r7g.large"  # Was cache.m7g.large

# Apply changes
terraform apply
```

### Scaling Up (Serverless)
```hcl
# Increase cache size
serverless_cache_size = 32  # Was 16

# Apply changes
terraform apply
```

### Changing Thresholds (Alarms)
```hcl
alarm_cpu_threshold = 85  # Was 75
alarm_memory_threshold = 90  # Was 80

# Apply changes
terraform apply
```

## Troubleshooting

**Issue: Secrets Manager secret not created**
- Ensure `auth_token_enabled = true`
- Ensure `auth_token` is 16-128 characters
- Check IAM permissions for SecretsManager

**Issue: CloudWatch logs not appearing**
- Ensure `cloudwatch_log_enabled = true`
- Ensure `create_log_groups = true` or log groups exist
- Wait a few minutes for logs to start appearing

**Issue: Alarms not triggering**
- Ensure `create_alarms = true`
- Ensure SNS topic exists and subscriptions are confirmed
- Check alarm thresholds are realistic for your workload

**Issue: Connection refused**
- Verify security group allows inbound traffic on port 6379
- Verify you're connecting from within the same VPC/security group
- Check cluster is in "available" state (check AWS console)

## Additional Resources

- [Module README](../README.md) - Full documentation and all configuration combinations
- [AWS ElastiCache Documentation](https://docs.aws.amazon.com/AmazonElastiCache/)
- [Valkey Documentation](https://valkey.io/)
