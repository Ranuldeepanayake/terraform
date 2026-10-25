# Route53 DNS for Valkey Endpoint

## Important: ElastiCache is Always Private

**ElastiCache always creates a private endpoint.** This is a fundamental AWS security model:
- ✅ Accessible: From within the same VPC only
- ❌ Not accessible: From outside the VPC, even with public Route53 records
- ❌ Not accessible: From different VPCs or regions directly (requires VPC peering, Transit Gateway, or PrivateLink)

Route53 records are purely for **DNS convenience**—they don't change the security model or make the endpoint publicly accessible.

## When DNS Resolution Issues Occur

ElastiCache endpoints may not resolve in these scenarios:

1. **Private VPC**: Endpoint needs Route53 private hosted zone for DNS
2. **Private Hosted Zone Not Associated**: Zone not associated with the VPC
3. **Application in Different VPC**: Needs VPC peering or Transit Gateway first
4. **Application in Different Region**: Needs cross-region networking setup
5. **Security Group Rules**: Port 6379 not allowed in inbound rules

## Solution: Route53 Private Hosted Zone (VPC-bound)

ElastiCache endpoints are **always private**, so you need a **private hosted zone** associated with your VPC:

```hcl
# Create a private hosted zone for your VPC
resource "aws_route53_zone" "private" {
  name = "internal.example.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}

# The module can automatically create a CNAME record
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"
  
  # ... other config ...
  
  # Enable Route53 integration
  create_route53_record = true
  route53_zone_id       = aws_route53_zone.private.zone_id
  route53_record_name   = null  # Defaults to cluster_id
}

# Use this DNS name in your application (VPC-only accessible)
output "cache_endpoint" {
  value       = module.elasticache_valkey.route53_record_fqdn
  description = "DNS name resolvable within the VPC"
  # Example output: caching-primary.internal.example.com:6379
}
```

**Important**: This endpoint is **only accessible from within the VPC**. The Route53 record just makes it easier to reference via DNS instead of the long AWS endpoint name.

### Cross-VPC Access

If you need access from a different VPC:
1. Set up VPC peering or Transit Gateway between VPCs
2. Associate the private hosted zone with the other VPC
3. Use the same Route53 record name (DNS will resolve within the other VPC)

**ElastiCache itself does NOT need any changes—only the DNS and networking infrastructure.**

## Solution 3: Route53 Alias Record (More Efficient)

Using Route53 Alias (no additional charge, faster failover):

```hcl
resource "aws_route53_zone" "private" {
  name = "internal.example.com"
  vpc {
    vpc_id = aws_vpc.main.id
  }
}

resource "aws_route53_record" "valkey_alias" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "cache.internal.example.com"
  type    = "A"

  # Note: Alias records require special routing (not direct CNAME for non-AWS targets)
  # For ElastiCache, use CNAME instead (Solution 1)
}
```

## Debugging DNS Issues

### Test DNS Resolution

```bash
# From within VPC/EC2 instance
nslookup cache.internal.example.com

# Or
dig cache.internal.example.com

# From anywhere with AWS CLI
aws route53 get-record --zone-id Z123ABC --name cache.internal.example.com

# Test direct ElastiCache endpoint
nslookup caching-primary.bykcyg.ng.0001.apse1.cache.amazonaws.com
```

### Check Route53 Configuration

```bash
# List hosted zones
aws route53 list-hosted-zones

# List records in zone
aws route53 list-resource-record-sets --zone-id Z123ABC

# Get specific record
aws route53 get-record --zone-id Z123ABC --name cache.internal.example.com
```

### Common Issues and Fixes

| Issue | Cause | Solution |
|-------|-------|----------|
| NXDOMAIN error | Record doesn't exist | Create Route53 record |
| Timeout | VPC can't reach DNS | Check Route53 zone VPC association |
| Resolution fails | Private zone not associated with VPC | Add VPC to hosted zone |
| Wrong IP | CNAME points to wrong endpoint | Update record to correct endpoint |
| Intermittent timeouts | TTL too high | Lower TTL (60 seconds) |

## Recommended Configuration

For production applications:

```hcl
# VPC-private hosted zone (most secure)
resource "aws_route53_zone" "internal" {
  name = "cache.internal"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}

# CNAME record for Valkey
resource "aws_route53_record" "valkey" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "primary.cache.internal"
  type    = "CNAME"
  ttl     = 60
  records = [module.elasticache_valkey.cluster_address]
}

# Also create for read replicas (if using Multi-AZ)
resource "aws_route53_record" "valkey_replica" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "replica.cache.internal"
  type    = "CNAME"
  ttl     = 60
  records = [module.elasticache_valkey.cluster_address]  # Same endpoint in Multi-AZ
}

output "cache_dns" {
  value = {
    primary = "primary.cache.internal:${module.elasticache_valkey.cluster_port}"
    replica = "replica.cache.internal:${module.elasticache_valkey.cluster_port}"
  }
  description = "Use these DNS names in your application config"
}
```

## Application Configuration

Update your application to use the Route53 DNS name:

### Environment Variables

```dotenv
# Instead of:
ELASTICACHE_HOST=caching-primary.bykcyg.ng.0001.apse1.cache.amazonaws.com

# Use:
ELASTICACHE_HOST=cache.internal.example.com
ELASTICACHE_PORT=6379
```

### Connection String

```
# Redis URL with Route53 DNS
redis://cache.internal.example.com:6379

# Or with password
redis://:password@cache.internal.example.com:6379
```

## Module Integration: Create Route53 Records

The Valkey module can create Route53 records when you provide a DNS name. If you don't provide a name, it uses the default AWS endpoint.

### Default Behavior (No Route53 Record)

By default, the module uses the AWS-provided endpoint:

```hcl
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  # ... other config ...

  # Use default endpoint (no Route53 record)
  create_route53_record = false  # or omit this (default)
}

output "cache_endpoint" {
  # Uses AWS default endpoint
  value = module.elasticache_valkey.primary_endpoint
  # Output example: prod-cache.bykcyg.ng.0001.apse1.cache.amazonaws.com:6379
}
```

### With Custom Route53 Record

Provide both the hosted zone and a custom DNS name to create a Route53 record:

```hcl
module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  # ... other config ...

  # Create a Route53 record
  create_route53_record = true
  route53_zone_id       = aws_route53_zone.internal.zone_id
  route53_record_name   = "cache.internal.example.com"  # Required to create record
}

output "cache_endpoint" {
  # Uses Route53 DNS record
  value = module.elasticache_valkey.route53_record_fqdn
  # Output: cache.internal.example.com:6379
}

output "direct_endpoint" {
  # Also available: the AWS default endpoint
  value = module.elasticache_valkey.primary_endpoint
}
```

### Using Defaults

If `route53_record_name` is not provided, the module automatically uses the cluster ID:

```hcl
locals {
  cluster_id = "prod-cache"
}

module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  cluster_id = local.cluster_id
  # ... config ...

  create_route53_record = true
  route53_zone_id       = aws_route53_zone.internal.zone_id
  route53_record_name   = null  # Defaults to cluster_id
}

# Result: Route53 record created with name "prod-cache"
output "cache_endpoint" {
  value = module.elasticache_valkey.route53_record_fqdn
  # Output: prod-cache.internal.example.com:6379 (automatically generated)
}
```

### Example: Complete Setup with Route53

```hcl
# Create private hosted zone
resource "aws_route53_zone" "internal" {
  name = "internal.example.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}

# Deploy Valkey with Route53 DNS record
module "elasticache_valkey" {
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

  # Security config...
  auth_token_enabled = true
  auth_token         = random_password.auth.result
  transit_encryption_enabled = true

  # Create Route53 record for DNS resolution
  create_route53_record = true
  route53_zone_id       = aws_route53_zone.internal.zone_id
  route53_record_name   = "cache.internal.example.com"  # Customize as needed

  tags = {
    Environment = "production"
  }
}

# Use this endpoint in your application config (DNS-resolvable)
output "cache_dns_endpoint" {
  value       = module.elasticache_valkey.route53_record_fqdn
  description = "Use this in your application: cache.internal.example.com:6379"
}

# Also available: the direct AWS endpoint (may have DNS resolution issues)
output "cache_aws_endpoint" {
  value       = module.elasticache_valkey.primary_endpoint
  description = "Direct AWS endpoint (for debugging)"
}
```

## See Also

- [AWS ElastiCache Networking](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/VPCs.html)
- [Route53 Private Hosted Zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html)
- [DNS Troubleshooting](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/troubleshooting.html)
