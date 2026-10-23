# ElastiCache Valkey Encryption Guide

This document explains the conditions, requirements, and client application changes needed for encryption at rest and in transit.

## Encryption at Rest

### Requirements

**Node Type Support:**
- ✅ Supported: `cache.t4g.*`, `cache.m7g.*`, `cache.r7g.*`, `cache.r6g.*`
- ❌ Not Supported: `cache.t3.*`, `cache.m5.*`, `cache.r5.*`

**Configuration:**
```hcl
at_rest_encryption_enabled    = true
at_rest_encryption_kms_key_id = "arn:aws:kms:region:account:key/key-id"
# Or null for AWS-managed key
```

**KMS Key Options:**
1. **AWS-Managed Key** (default, recommended for most users)
   - Free to use
   - Automatic key rotation
   - No manual management
   ```hcl
   at_rest_encryption_kms_key_id = null
   ```

2. **Customer-Managed Key** (full control, required for specific compliance)
   - Additional cost per key
   - Manual key rotation policy
   - Full audit trail
   ```hcl
   at_rest_encryption_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
   ```

### Client Application Changes

**No changes required!** At-rest encryption is transparent to clients:
- Data is encrypted automatically on disk
- Data is decrypted automatically in memory
- Clients connect exactly the same way
- Connection protocol unchanged
- No TLS/SSL configuration needed

### Performance Impact

- **Minimal**: ~5% latency increase or less for most workloads
- **Trade-off**: Security vs slight performance penalty (usually negligible)

---

## Transit Encryption (TLS)

### Requirements

**Node Type Support:**
- ✅ Supported: `cache.t4g.*`, `cache.m7g.*`, `cache.r7g.*`
- ❌ Not Supported: `cache.t3.*`, `cache.m5.*`, `cache.r5.*`

**Configuration:**
```hcl
transit_encryption_enabled = true
transit_encryption_mode    = "required"  # or "preferred"
```

**Modes Explained:**

| Mode | Behavior | Use Case |
|------|----------|----------|
| `"preferred"` | Allows both encrypted and unencrypted connections | Gradual migration, development |
| `"required"` | Only encrypted connections allowed | Production, compliance requirements |

**Authentication Interaction:**

When `transit_encryption_enabled = true` and `transit_encryption_mode = "required"`:
- You **should** enable `auth_token_enabled = true`
- AUTH token provides both authentication AND encryption
- Some configurations may require it

```hcl
transit_encryption_enabled = true
transit_encryption_mode    = "required"
auth_token_enabled         = true
auth_token                 = random_password.valkey_auth.result
```

### Client Application Changes

**YES - Clients MUST be updated to use TLS!**

#### Python Example

**Without TLS (not safe for encrypted clusters):**
```python
import redis

# This will FAIL if transit_encryption_enabled = true and mode = "required"
client = redis.Redis(
    host='prod-cache.xxxxx.cache.amazonaws.com',
    port=6379,
    decode_responses=True
)
```

**With TLS (correct for encrypted clusters):**
```python
import redis
import ssl

# Create SSL context
ssl_context = ssl.create_default_context()
# For self-signed certs (not recommended for production):
# ssl_context.check_hostname = False
# ssl_context.verify_mode = ssl.CERT_NONE

client = redis.Redis(
    host='prod-cache.xxxxx.cache.amazonaws.com',
    port=6379,
    ssl=True,
    ssl_certfile=None,  # Use system CA bundle
    ssl_keyfile=None,
    ssl_ca_certs=None,  # Use system CA bundle
    ssl_cert_reqs='required',
    decode_responses=True
)

# If AUTH is enabled, add password:
# client = redis.Redis(
#     host='...',
#     port=6379,
#     password='auth-token-value',
#     ssl=True,
#     ssl_cert_reqs='required',
#     decode_responses=True
# )
```

#### Node.js Example

**Without TLS (not safe for encrypted clusters):**
```javascript
const redis = require('redis');

// This will FAIL if transit_encryption_enabled = true and mode = "required"
const client = redis.createClient({
  host: 'prod-cache.xxxxx.cache.amazonaws.com',
  port: 6379
});
```

**With TLS (correct for encrypted clusters):**
```javascript
const redis = require('redis');
const tls = require('tls');

const client = redis.createClient({
  host: 'prod-cache.xxxxx.cache.amazonaws.com',
  port: 6379,
  tls: {
    rejectUnauthorized: true,
    // AWS uses valid certificates, no custom CA needed
  },
  // If AUTH is enabled:
  password: 'auth-token-value'
});
```

#### Go Example

**Without TLS (not safe for encrypted clusters):**
```go
import "github.com/go-redis/redis/v8"

// This will FAIL if transit_encryption_enabled = true and mode = "required"
client := redis.NewClient(&redis.Options{
    Addr: "prod-cache.xxxxx.cache.amazonaws.com:6379",
})
```

**With TLS (correct for encrypted clusters):**
```go
import (
    "crypto/tls"
    "github.com/go-redis/redis/v8"
)

client := redis.NewClient(&redis.Options{
    Addr: "prod-cache.xxxxx.cache.amazonaws.com:6379",
    TLSConfig: &tls.Config{
        InsecureSkipVerify: false,  // Verify certificates
        MinVersion:        tls.VersionTLS12,
    },
    // If AUTH is enabled:
    Password: "auth-token-value",
})
```

#### Java Example

**Without TLS (not safe for encrypted clusters):**
```java
import redis.clients.jedis.Jedis;

// This will FAIL if transit_encryption_enabled = true and mode = "required"
Jedis jedis = new Jedis("prod-cache.xxxxx.cache.amazonaws.com", 6379);
```

**With TLS (correct for encrypted clusters):**
```java
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisClientConfig;
import redis.clients.jedis.Protocol;

JedisClientConfig config = DefaultJedisClientConfig.builder()
    .ssl(true)
    .protocol(Protocol.RESP3)
    // If AUTH is enabled:
    .password("auth-token-value")
    .build();

Jedis jedis = new Jedis("prod-cache.xxxxx.cache.amazonaws.com", 6379, config);
```

### Performance Impact

- **Moderate**: ~10-15% latency increase depending on workload
- **CPU overhead**: ~5-10% due to encryption/decryption
- **Trade-off**: Security vs performance (usually acceptable for production)

---

## Recommended Encryption Configurations

### Development Environment
```hcl
# Minimal encryption for cost
at_rest_encryption_enabled  = false
transit_encryption_enabled  = false
auth_token_enabled          = false
```

### Staging Environment
```hcl
# Test encryption setup before production
at_rest_encryption_enabled    = true
at_rest_encryption_kms_key_id = null  # AWS-managed key

transit_encryption_enabled = true
transit_encryption_mode    = "preferred"  # Allow unencrypted for migration
auth_token_enabled         = false  # Optional in preferred mode
```

### Production Environment
```hcl
# Full encryption for security compliance
at_rest_encryption_enabled    = true
at_rest_encryption_kms_key_id = "arn:aws:kms:..."  # Customer-managed key for compliance

transit_encryption_enabled = true
transit_encryption_mode    = "required"  # Enforce encryption
auth_token_enabled         = true  # Require authentication
auth_token                 = random_password.valkey_auth.result
```

---

## Migration Strategy: Adding Encryption to Existing Cluster

### Step 1: Enable Preferred Mode (Non-Breaking)
```hcl
# Old apps work, new apps can use encryption
transit_encryption_enabled = true
transit_encryption_mode    = "preferred"
```

### Step 2: Update All Client Applications
- Update all clients to use TLS
- Test thoroughly in staging
- Deploy to production

### Step 3: Enable Required Mode (Enforce Encryption)
```hcl
# After all clients updated
transit_encryption_enabled = true
transit_encryption_mode    = "required"
```

### Step 4: Enable At-Rest Encryption
```hcl
# Transparent to clients, enable once TLS is working
at_rest_encryption_enabled    = true
at_rest_encryption_kms_key_id = "arn:aws:kms:..."
```

---

## Verification Checklist

### Before Enabling Transit Encryption

- [ ] All client libraries support TLS
- [ ] All applications can connect via TLS
- [ ] Test connections with TLS enabled in staging
- [ ] Verify certificate validation works
- [ ] Check performance is acceptable

### After Enabling Transit Encryption

- [ ] Monitor cluster metrics for performance impact
- [ ] Check error logs for connection failures
- [ ] Verify no auth/connection errors in application logs
- [ ] Confirm all clients are using TLS

---

## Troubleshooting

### Client Cannot Connect After Enabling Encryption

**Error: "Connection refused" or "Connection timed out"**
```
Cause: Client not using TLS
Solution: Update client to use TLS/SSL
```

**Error: "SSL: CERTIFICATE_VERIFY_FAILED"**
```
Cause: Certificate verification failing
Solution: Ensure system CA bundle is up to date, or use correct ssl_ca_certs
```

**Error: "AUTH <token>"**
```
Cause: AUTH token required but not provided
Solution: Add password/auth_token to client connection
```

### Performance Issues After Enabling Encryption

**Symptom: 15%+ latency increase**
```
Possible causes:
1. Network bandwidth saturated by encryption overhead
2. CPU at capacity due to encryption
3. Client-side encryption overhead

Solutions:
1. Monitor CloudWatch metrics
2. Increase node type if needed
3. Profile client application
```

---

## AWS Certificate Authority

AWS uses valid certificates issued by trusted CAs (Amazon Root CA). You can verify:

```bash
# Check certificate chain
openssl s_client -connect prod-cache.xxxxx.cache.amazonaws.com:6379 -showcerts

# Verify certificate validity
openssl s_client -connect prod-cache.xxxxx.cache.amazonaws.com:6379 -showcerts | \
  openssl x509 -noout -dates
```

Most clients will automatically validate using the system CA bundle. No custom certificate needed for AWS ElastiCache.

---

## Cost Impact

### At-Rest Encryption
- **AWS-managed key**: No additional cost
- **Customer-managed key**: ~$1.00 USD per key per month

### Transit Encryption
- **Performance impact**: May require larger node type
- **No direct cost**: Just pay for the additional compute if needed

### Authentication Token in Secrets Manager
- **Cost**: Standard Secrets Manager pricing (~$0.40 USD per secret per month)
- **Benefit**: Centralized secret management and audit trail

---

## Related Documentation

- [AWS ElastiCache Encryption at Rest](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/encryption-at-rest.html)
- [AWS ElastiCache In-Transit Encryption](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/in-transit-encryption.html)
- [Redis Client Libraries](https://redis.io/docs/clients/) - Check TLS support for your language
