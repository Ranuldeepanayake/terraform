# AUTH Token Requirement: Transit Encryption Required

## The Requirement

**AUTH tokens in Valkey require transit encryption (TLS) to be enabled.**

If you enable `auth_token_enabled = true`, you MUST also enable `transit_encryption_enabled = true`.

### Why This Requirement Exists

AWS enforces this for security reasons:

1. **AUTH tokens send credentials over the network** — They authenticate clients to the server
2. **Unencrypted credentials are vulnerable** — Without TLS, credentials could be intercepted
3. **TLS provides encryption in transit** — Protects the token from being captured on the network
4. **Defense in depth** — AUTH + TLS creates multiple layers of security

---

## Correct Configuration

### ✅ Correct: AUTH + Transit Encryption

```hcl
module "valkey_secure" {
  source = "../../modules/elasticache-valkey"

  # ... other config ...

  # Authentication
  auth_token_enabled = true
  auth_token         = "your-secure-token-16-128-chars"

  # Transit Encryption (REQUIRED for AUTH)
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"
}
```

### ❌ Incorrect: AUTH Without Transit Encryption

```hcl
module "valkey_insecure" {
  source = "../../modules/elasticache-valkey"

  # ... other config ...

  # Authentication enabled
  auth_token_enabled = true
  auth_token         = "your-token"

  # ERROR: Transit encryption is DISABLED
  transit_encryption_enabled = false  # ❌ CAUSES ERROR
}
```

Error:
```
Error: InvalidParameterValue: The AUTH token is only supported when 
encryption-in-transit is enabled
```

### ✅ Correct: No AUTH, No Transit Encryption (Development Only)

```hcl
module "valkey_dev_minimal" {
  source = "../../modules/elasticache-valkey"

  # ... other config ...

  # No authentication
  auth_token_enabled = false

  # No transit encryption
  transit_encryption_enabled = false
}
```

---

## Implementation Patterns

### Pattern 1: Production - Full Security (AUTH + TLS + At-Rest)

```hcl
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "random_password" "auth_token" {
  length  = 32
  special = true
}

resource "aws_kms_key" "cache" {
  description             = "KMS key for cache encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

module "valkey_production" {
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

  parameter_group_name = "default.valkey8.0"

  # ========== SECURITY: Full Stack ==========
  
  # Authentication (requires TLS)
  auth_token_enabled = true
  auth_token         = random_password.auth_token.result
  auth_secret_name   = "prod/cache/auth-token"

  # Transit Encryption (required for AUTH)
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"  # Enforce TLS

  # At-Rest Encryption
  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn

  # ========== MONITORING ==========
  
  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 30

  create_alarms       = true
  create_sns_topic    = true
  alert_email_addresses = ["ops@company.com"]

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
    Security    = "full-encryption-auth"
  }
}

output "cache_endpoint" {
  value = module.valkey_production.primary_endpoint
}

output "auth_secret_arn" {
  value = module.valkey_production.auth_secret_arn
}
```

### Pattern 2: Staging - AUTH Only (TLS Required)

```hcl
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "random_password" "auth_token" {
  length  = 32
  special = true
}

module "valkey_staging" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "staging-cache"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 1

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  parameter_group_name = "default.valkey8.0"

  # ========== SECURITY: AUTH + TLS ==========
  
  # Authentication (requires TLS)
  auth_token_enabled = true
  auth_token         = random_password.auth_token.result
  auth_secret_name   = "staging/cache/auth-token"

  # Transit Encryption (required for AUTH)
  transit_encryption_enabled = true
  transit_encryption_mode    = "preferred"  # Clients can choose TLS

  # At-Rest Encryption (optional for staging)
  at_rest_encryption_enabled = false

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "staging"
    Security    = "tls-auth"
  }
}

output "cache_endpoint" {
  value = module.valkey_staging.primary_endpoint
}
```

### Pattern 3: Development - No Authentication

```hcl
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

module "valkey_dev" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "dev-cache"
  engine_version  = "8.0"
  node_type       = "cache.t4g.micro"
  num_cache_nodes = 1

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  parameter_group_name = "default.valkey8.0"

  # ========== NO SECURITY ==========
  
  # No authentication
  auth_token_enabled = false

  # No transit encryption
  transit_encryption_enabled = false

  # No at-rest encryption
  at_rest_encryption_enabled = false

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "development"
    Security    = "none"
  }
}

output "cache_endpoint" {
  value = module.valkey_dev.primary_endpoint
}
```

---

## Transit Encryption Modes

When `transit_encryption_enabled = true`, choose a mode:

| Mode | Behavior | Use Case |
|------|----------|----------|
| `"required"` | All connections must use TLS | Production (enforced security) |
| `"preferred"` | TLS is offered but not enforced | Staging/migration (gradual rollout) |

### Recommended

- **Production**: Use `"required"` to enforce security
- **Staging**: Use `"preferred"` to allow gradual client migration
- **Development**: Set `transit_encryption_enabled = false` to simplify local testing

---

## Client Connection Examples

Once your cache is deployed with AUTH + TLS:

### Python with redis-py

```python
import redis
import ssl

# Create SSL context
ssl_context = ssl.create_default_context()

# Connect with AUTH token and TLS
client = redis.Redis(
    host='your-endpoint.cache.amazonaws.com',
    port=6379,
    password='your-auth-token',
    ssl=True,
    ssl_context=ssl_context,
    ssl_cert_reqs='required'
)

# Test connection
client.ping()
print("Connected successfully!")
```

### Node.js with ioredis

```javascript
const Redis = require('ioredis');

// Connect with AUTH token and TLS
const client = new Redis({
  host: 'your-endpoint.cache.amazonaws.com',
  port: 6379,
  password: 'your-auth-token',
  tls: {}  // Enable TLS
});

client.ping().then(() => {
  console.log('Connected successfully!');
});
```

### Java with Jedis

```java
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

JedisPoolConfig config = new JedisPoolConfig();
config.setMaxTotal(10);

JedisPool pool = new JedisPool(
    config,
    "your-endpoint.cache.amazonaws.com",
    6379,
    2000,
    "your-auth-token",
    true  // SSL enabled
);

Jedis jedis = pool.getResource();
System.out.println(jedis.ping());
```

---

## Troubleshooting

### Error: AUTH token not supported without encryption-in-transit

**Cause**: You set `auth_token_enabled = true` but `transit_encryption_enabled = false`

**Fix**: Enable transit encryption:

```hcl
auth_token_enabled         = true
transit_encryption_enabled = true
transit_encryption_mode    = "required"
```

### Error: Connection refused with AUTH token

**Cause**: Client is connecting without TLS while server requires TLS

**Fix**: Ensure your client code enables TLS/SSL

### Error: AUTH failed - invalid password

**Cause**: Wrong token being sent or token not created in Secrets Manager

**Fix**: Verify the token in Secrets Manager matches what clients are using:

```bash
aws secretsmanager get-secret-value \
  --secret-id prod/cache/auth-token \
  --query SecretString
```

---

## Best Practices

1. **Always use AUTH + TLS together** — Never use one without the other
2. **Use "required" mode in production** — Enforce TLS security
3. **Store tokens in Secrets Manager** — Don't hardcode credentials
4. **Rotate tokens regularly** — Update Secrets Manager value
5. **Monitor auth failures** — Use CloudWatch logs to detect issues
6. **Test client connectivity** — Verify TLS + AUTH before deploying
7. **Document token format** — Make it clear that clients need both TLS and token

---

## See Also

- [IAM Setup & Roles](./IAM-SETUP.md)
- [Encryption Configuration](./ENCRYPTION.md)
- [PROVISIONED-SINGLE-INSTANCE.md](./PROVISIONED-SINGLE-INSTANCE.md)
- [PROVISIONED-MULTI-AZ.md](./PROVISIONED-MULTI-AZ.md)
- [AWS ElastiCache AUTH Documentation](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/auth.html)
