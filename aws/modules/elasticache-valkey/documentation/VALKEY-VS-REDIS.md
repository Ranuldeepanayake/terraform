# Valkey vs Redis: Strategic Decision Guide

## Why Valkey and Not Redis 7.4?

This is a critical architectural decision made by AWS. Understanding the context is essential for long-term planning.

---

## The License Change (March 2024)

### Before: Redis Was Fully Open-Source

- **License**: BSD (permissive open-source)
- **Usage**: Anyone could use, modify, offer as service
- **Cost**: Free for cloud providers to offer

```
BSD License
  ↓
Anyone can commercialize
  ↓
AWS, Azure, Google Cloud all offered Redis
```

### After: Redis Became Proprietary-Friendly

- **New License**: Commons Clause + SSPLv1
- **Impact**: Restricts cloud provider offerings
- **Cost**: Cloud providers must pay Redis Labs licensing fees
- **Result**: AWS and others moved away from Redis

```
Commons Clause + SSPL License
  ↓
Cloud providers need commercial license
  ↓
Must pay Redis Labs per deployment
  ↓
AWS switched to Valkey instead
```

---

## What is Valkey?

**Valkey = Community Fork of Redis**

- **Created**: March 2024 (before Redis license change)
- **Based on**: Redis 7.0 source code
- **License**: BSD (open-source, no restrictions)
- **Compatibility**: 100% drop-in replacement for Redis
- **Maintainers**: Linux Foundation (community-driven)
- **Governance**: Open community model (like Linux)

### Valkey Timeline

| Date | Event |
|------|-------|
| 2024-03 | Redis changes license to Commons Clause + SSPL |
| 2024-03 | Valkey project launched as open-source fork |
| 2024-04 | Linux Foundation adopts Valkey |
| 2024-Q3 | AWS adds Valkey to ElastiCache |
| 2024-Q4 | Valkey 8.0 released |
| 2025+ | Valkey continues active development |

---

## Redis 8: Why AWS Won't Offer It

### Redis 8 Will Use the Same Restrictive License

```
Redis 8 License = Commons Clause + SSPL (same as 7.4)
  ↓
Cloud providers still can't offer it freely
  ↓
AWS will NOT add Redis 8 support
  ↓
Users should use Valkey 9.0+ instead
```

### The Business Impact

| Factor | Redis 8 | Valkey |
|--------|---------|--------|
| **License** | Commons Clause + SSPL | BSD (open-source) |
| **AWS Offering** | ❌ Not available | ✅ Available |
| **Cost to Users** | Would be higher (licensing passed through) | Standard AWS pricing |
| **Vendor Lock-in** | High (Redis Labs controls) | Low (Linux Foundation) |
| **Long-term Support** | Vendor-dependent | Community-driven |
| **Version Upgrades** | Requires Redis Labs approval | Community decides |

---

## Long-Term Support: Valkey Wins

### Valkey: Community-Driven Sustainability

```
Linux Foundation governance
  ↓
Open community contributions
  ↓
No single vendor lock-in
  ↓
Guaranteed long-term support
```

**Examples of Linux Foundation projects with 20+ years support:**
- Linux kernel
- Kubernetes
- Apache projects
- Node.js

### Redis 7.4+: Vendor-Dependent Risk

```
Redis Labs controls releases
  ↓
License restrictions limit adoption
  ↓
Pressure to monetize
  ↓
Support tied to commercial terms
```

**Risk**: Redis Labs could:
- Raise licensing fees
- Discontinue versions
- Add more restrictions
- Force upgrades on their terms

---

## Migration Path: Redis → Valkey

### Why You Should Use Valkey Now

1. **100% Compatible** — Drop-in replacement for Redis
2. **Future-Proof** — Won't face licensing issues
3. **Cost Control** — No licensing fees passed to users
4. **Community Driven** — Transparent development
5. **AWS Strategic Choice** — AWS bet its future on Valkey
6. **Ecosystem Support** — All major tools support Valkey

### If You're Currently Using Redis

**Current state (Redis 7.x)**: Still works fine, no rush to migrate

**Migration timeline**:
- **Now**: Start new projects with Valkey
- **2025**: Plan Redis 7.x → Valkey migration
- **2026**: Move production Redis 7.x to Valkey
- **2027+**: Sunset Redis 7.x

**Simple migration**:
```bash
# Valkey is 100% compatible with Redis clients
# No code changes needed
# Just update ElastiCache cluster engine version

# Before: Redis 7.4
# After: Valkey 8.0 or 9.0
# Client code: No changes required
```

---

## Version Comparison

### Current Versions

| Engine | Version | License | Support | AWS | Status |
|--------|---------|---------|---------|-----|--------|
| **Valkey** | 8.0 | BSD | 🔴 Active | ✅ Yes | ← **Choose this** |
| **Valkey** | 9.0 | BSD | 🟢 Active | ✅ Yes | ← **Or this** |
| **Redis** | 7.0 | BSD | 🟡 Limited | ✅ Yes | Sunset path |
| **Redis** | 7.2 | Commons Clause | 🟡 Limited | ✅ Yes | Sunset path |
| **Redis** | 8.0 | Commons Clause | ⚠️ Restricted | ❌ No | Avoid |

### Legend
- 🟢 **Active**: Full support, recommended for new projects
- 🟡 **Limited**: Works but planned for sunset
- 🔴 **Critical**: Use only if required for legacy systems
- ⚠️ **Restricted**: Licensing issues, avoid if possible

---

## Architecture Decision: Why This Module Uses Valkey

This Terraform module is built for **Valkey specifically** because:

1. **Future-proof** — Won't face licensing headaches
2. **AWS strategic choice** — Aligns with AWS direction
3. **Community standard** — Ecosystem consensus on Valkey
4. **No licensing worries** — BSD license is clean and simple
5. **Long-term support** — Linux Foundation backing

---

## Practical Implications

### For New Projects

```hcl
# ✅ Recommended: Use Valkey
module "cache" {
  source = "../../modules/elasticache-valkey"
  
  engine_version = "9.0"  # Latest Valkey
}
```

### For Existing Redis Users

```hcl
# 🟡 Acceptable: Keep Redis 7.x for now
# But plan to migrate to Valkey 8.0+ within 12 months

# Timeline:
# - Q1 2025: Start migration planning
# - Q2 2025: Test Valkey in staging
# - Q3 2025: Roll out to production
# - Q4 2025: Sunset Redis 7.x
```

### Migration Example

```hcl
# BEFORE: Redis 7.4
module "cache_old" {
  source = "../../modules/elasticache-redis"
  
  engine         = "redis"
  engine_version = "7.4"
}

# AFTER: Valkey 9.0
module "cache_new" {
  source = "../../modules/elasticache-valkey"
  
  engine_version = "9.0"
}

# Client code: No changes needed!
# Valkey is 100% compatible with Redis clients
```

---

## FAQ

### Q: Should we migrate away from Redis immediately?

**A**: No need to rush. Redis 7.x still works fine. Plan migration for 2025.

### Q: Will Redis 8 ever be available in AWS?

**A**: Very unlikely. AWS has committed to Valkey long-term.

### Q: Is Valkey production-ready?

**A**: Yes. Used in production by major companies. AWS stands behind it.

### Q: Do we need to change our application code?

**A**: No. Valkey is a drop-in replacement. No code changes needed.

### Q: What about Redis modules and extensions?

**A**: Most popular modules work with Valkey. Check specific module compatibility.

### Q: Is there a performance difference?

**A**: No. Valkey maintains Redis performance while fixing open-source bugs.

### Q: What if we need Redis 8 features?

**A**: Valkey follows similar feature releases. Valkey 9.0+ adds modern features.

---

## Resources

- [Valkey Official Website](https://valkey.io/)
- [Linux Foundation: Valkey](https://www.linuxfoundation.org/projects/valkey/)
- [AWS ElastiCache: Valkey Support](https://docs.aws.amazon.com/AmazonElastiCache/)
- [Redis License Change (March 2024)](https://redis.io/blog/redis-license-update/)
- [Why We Forked Redis (Blog)](https://aws.amazon.com/blogs/database/valkey-open-source-project/)

---

## See Also

- [PROVISIONED-SINGLE-INSTANCE.md](./PROVISIONED-SINGLE-INSTANCE.md)
- [PROVISIONED-MULTI-AZ.md](./PROVISIONED-MULTI-AZ.md)
- [DEPLOYMENT-MODES.md](./DEPLOYMENT-MODES.md)
