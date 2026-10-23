# ElastiCache Valkey Deployment Modes

This guide documents all valid combinations of `num_cache_nodes`, `multi_az_enabled`, and `automatic_failover_enabled`.

## Valid Combinations

### 1. Single-Node Development (No HA)

```hcl
num_cache_nodes            = 1
multi_az_enabled           = false
automatic_failover_enabled = false
```

**Characteristics:**
- Single cache node, no replication
- No high availability
- Best for: Development, testing, non-critical workloads
- Cost: Lowest
- Data loss risk: High (node failure = data loss)
- Snapshots: ✅ Supported

**Use Cases:**
- Local development environments
- Testing and staging (non-critical)
- Cost-conscious proof-of-concepts

**Risks:**
- ❌ No automatic failover
- ❌ No data protection on node failure
- ❌ Downtime during maintenance

---

### 2. Single-Node with Snapshots (Manual Backup Only)

```hcl
num_cache_nodes            = 1
multi_az_enabled           = false
automatic_failover_enabled = false

# Add backup configuration
snapshot_retention_limit = 7  # Enable snapshots for single-node
snapshot_window          = "03:00-05:00"
```

**Characteristics:**
- Single node with periodic snapshots
- Manual recovery only (no automatic failover)
- Best for: Dev environments with backup requirements
- Cost: Low (single node + snapshot storage)
- Data loss risk: Low (if snapshots are recent)
- Snapshots: ✅ Supported

**Use Cases:**
- Development with data persistence requirement
- Non-critical services that need backup
- Learning/training environments

---

### 3. Multi-Node Without Multi-AZ (Manual Failover Only)

```hcl
num_cache_nodes            = 2  # or more
multi_az_enabled           = false
automatic_failover_enabled = false
```

**Characteristics:**
- 2+ nodes in same AZ with replication
- Manual failover only (no automatic failover)
- No cross-AZ protection
- Cost: Medium (multiple nodes, single AZ)
- HA: Partial (replication, manual failover)
- Data loss risk: Low (replicated)
- Snapshots: ❌ Not supported (only for single-node)

**Valid node counts:**
- 2 nodes: Primary + 1 replica
- 3+ nodes: Primary + multiple replicas

**Use Cases:**
- Cost-conscious high-availability
- Workloads where manual failover is acceptable
- Environments with operational oversight

**Trade-off:**
- ✅ Replication for data protection
- ✅ Can promote replica manually on failure
- ❌ Requires manual intervention
- ❌ No cross-AZ redundancy

---

### 4. Multi-AZ with Automatic Failover (Production HA)

```hcl
num_cache_nodes            = 2  # or more
multi_az_enabled           = true
automatic_failover_enabled = true
```

**Characteristics:**
- Nodes spread across multiple AZs
- Automatic failover on node/AZ failure
- Best for: Production, mission-critical workloads
- Cost: Medium-High (multi-AZ + replication)
- HA: High (automatic failover)
- Data loss risk: Very Low (replicated + auto-failover)
- Snapshots: ❌ Not supported (Multi-AZ requires cluster mode)
- Downtime: ~1-2 minutes on AZ failure (automatic)

**Requirements:**
- At least 2 subnets in different AZs
- 2+ nodes (primary + replicas)

**Valid configurations:**
```hcl
# Minimum HA setup (2 nodes, 2 AZs)
num_cache_nodes = 2
subnet_ids      = [subnet_az1, subnet_az2]

# Enhanced HA setup (3 nodes, 3 AZs)
num_cache_nodes = 3
subnet_ids      = [subnet_az1, subnet_az2, subnet_az3]
```

**Use Cases:**
- Production systems requiring high availability
- Mission-critical data caches
- SaaS platforms with SLA requirements
- E-commerce and payment systems

**Benefits:**
- ✅ Automatic failover on failure
- ✅ Cross-AZ redundancy
- ✅ Transparent to applications
- ✅ Maintains service during maintenance

---

### 5. Multi-Node Multi-AZ Without Automatic Failover

```hcl
num_cache_nodes            = 2  # or more
multi_az_enabled           = true
automatic_failover_enabled = false
```

**Characteristics:**
- Nodes in multiple AZs
- No automatic failover (manual promotion only)
- Cost: Medium (multi-AZ + replication)
- HA: Medium (cross-AZ, manual failover)

**Valid, but rare use case:**
- Compliance requirement for multi-AZ but no auto-failover
- Environments with monitoring/alerting that handles failover
- Cost optimization (multi-AZ protection but avoid auto-failover overhead)

**Trade-off:**
- ✅ Cross-AZ redundancy
- ✅ Lower costs than with auto-failover
- ❌ Requires manual intervention on failure

---

## Invalid Combinations

### ❌ Single-Node with Multi-AZ
```hcl
num_cache_nodes  = 1
multi_az_enabled = true  # INVALID!
```

**Why invalid:**
- Multi-AZ requires replication
- Single node cannot replicate

**Error message:**
```
Error: Invalid configuration
Multi-AZ requires at least 2 cache nodes
```

---

### ❌ Single-Node with Automatic Failover
```hcl
num_cache_nodes            = 1
automatic_failover_enabled = true  # INVALID!
```

**Why invalid:**
- Failover requires either:
  - Multi-AZ enabled, OR
  - 2+ nodes
- Single node has nothing to failover to

**Error message:**
```
automatic_failover_enabled requires either multi_az_enabled=true or num_cache_nodes > 1
```

---

### ❌ Multi-Node with Failover but No Multi-AZ or Nodes

```hcl
num_cache_nodes            = 1
multi_az_enabled           = false
automatic_failover_enabled = true  # INVALID!
```

Same as above - failover requires Multi-AZ or 2+ nodes.

---

## Decision Matrix

| Goal | Configuration | HA Level | Cost | Best For |
|------|---|---|---|---|
| **Minimal** | 1 node, no Multi-AZ, no failover | None | Lowest | Development |
| **Backup Protection** | 1 node + snapshots | Low | Low | Dev with persistence |
| **Replication Only** | 2+ nodes, no Multi-AZ, no auto-failover | Medium | Medium | Cost-conscious HA |
| **Cross-AZ Protection** | 2+ nodes, Multi-AZ, no auto-failover | Medium | Medium | Compliance HA |
| **Full Production HA** | 2+ nodes, Multi-AZ, auto-failover | High | Medium-High | Production |

---

## Recommended Configurations by Environment

### Development
```hcl
num_cache_nodes            = 1
multi_az_enabled           = false
automatic_failover_enabled = false

# Optional: add snapshots for data persistence
snapshot_retention_limit = 0  # Disabled
```

### Staging
```hcl
# Option A: Test Multi-AZ setup before production
num_cache_nodes            = 2
multi_az_enabled           = true
automatic_failover_enabled = true

# Option B: Cost-conscious staging
num_cache_nodes            = 1
multi_az_enabled           = false
automatic_failover_enabled = false
```

### Production
```hcl
# Standard production HA
num_cache_nodes            = 2
multi_az_enabled           = true
automatic_failover_enabled = true

# Or for enhanced redundancy:
num_cache_nodes            = 3
multi_az_enabled           = true
automatic_failover_enabled = true
```

---

## Failover Behavior

### No Automatic Failover (manual_failover_enabled = false)

```
Node Failure:
┌─────────────┐
│ Primary     │ ← Fails
└─────────────┘

┌─────────────┐
│ Replica     │ ← Remains replica
└─────────────┘

Action Required: Manual promotion of replica
Recovery Time: ~5-30 minutes (manual intervention)
```

### Automatic Failover Enabled (auto_failover_enabled = true)

```
Node Failure:
┌─────────────┐
│ Primary     │ ← Fails (AZ1)
└─────────────┘

┌─────────────┐
│ Replica     │ ← Auto-promoted to Primary (AZ2)
└─────────────┘

Action Required: None (automatic)
Recovery Time: ~1-2 minutes (automatic)
```

---

## Failover Scenarios

### Scenario 1: Single-Node Failure (no HA)
```
Before: [Node1] → FAIL → Complete downtime
After:  [Node1] → Offline until manual recovery
```

### Scenario 2: Primary Node Failure (Multi-Node, no Auto-Failover)
```
Before: [Primary] ← Failover Required → [Replica]
After:  Manual promotion takes 5-30 minutes
```

### Scenario 3: Primary Node Failure (Multi-AZ, Auto-Failover)
```
Before: [Primary - AZ1] ← Auto-Failover → [Replica - AZ2]
After:  1-2 minute automatic recovery, service continues
```

### Scenario 4: Entire AZ Failure (Multi-AZ, Auto-Failover)
```
Before: [Primary - AZ1] [Replica1 - AZ1] [Replica2 - AZ2]
        ← All in AZ1 fail, but AZ2 remains
After:  [Replica2 - AZ2] ← Promoted automatically
        ~1-2 minute automatic recovery
```

---

## Configuration Constraints & Validations

The module enforces these rules:

1. **Node Count Range:**
   ```hcl
   num_cache_nodes must be 1-500
   ```

2. **Failover Requirements:**
   ```hcl
   If automatic_failover_enabled = true:
     THEN (multi_az_enabled = true) OR (num_cache_nodes >= 2)
   ```

3. **Multi-AZ Requirements:**
   ```hcl
   If multi_az_enabled = true:
     THEN num_cache_nodes >= 2 (implicit)
     AND provide 2+ subnets in different AZs
   ```

4. **Snapshot Limitations:**
   ```hcl
   If snapshot_retention_limit > 0:
     THEN num_cache_nodes = 1 (single-node only)
   ```

---

## Migration Paths

### Single-Node → Multi-Node (no downtime possible)

**Option 1: Create new cluster (requires migration)**
```hcl
# Step 1: Create new multi-node cluster
num_cache_nodes = 2
multi_az_enabled = true
automatic_failover_enabled = true

# Step 2: Migrate data from old cluster to new cluster
# Step 3: Update applications to use new endpoint
# Step 4: Delete old cluster
```

**Option 2: Replace cluster (requires downtime)**
```hcl
# Modify existing cluster - requires recreation
# This causes brief downtime as cluster is replaced
```

### Multi-Node → Multi-AZ HA (minimal downtime)

```hcl
# Before:
num_cache_nodes = 2
multi_az_enabled = false
automatic_failover_enabled = false

# After:
num_cache_nodes = 2
multi_az_enabled = true  # Add Multi-AZ
automatic_failover_enabled = true  # Enable auto-failover

# AWS handles this with brief replication lag (~1-2 minutes)
```

---

## Troubleshooting

### "Cannot enable automatic failover on single-node cluster"

**Problem:**
```hcl
num_cache_nodes = 1
automatic_failover_enabled = true  # ERROR!
```

**Solution:**
```hcl
# Either:
num_cache_nodes = 2  # Add more nodes, OR
multi_az_enabled = true  # Add Multi-AZ (requires 2+ nodes)
```

---

### "Multi-AZ requires subnets in different AZs"

**Problem:**
```hcl
multi_az_enabled = true
subnet_ids = ["subnet-1", "subnet-2"]  # Both in same AZ!
```

**Solution:**
```hcl
subnet_ids = [
  "subnet-1a",  # AZ us-east-1a
  "subnet-1b"   # AZ us-east-1b (different!)
]
```

---

## Cost Comparison

| Configuration | Node Cost | Multi-AZ Cost | Failover Cost | Total |
|---|---|---|---|---|
| 1 node, no HA | $X | - | - | $X |
| 2 nodes, no Multi-AZ | $2X | - | - | $2X |
| 2 nodes, Multi-AZ | $2X | $Y | - | $2X + $Y |
| 2 nodes, Multi-AZ, auto-failover | $2X | $Y | $Z | $2X + $Y + $Z |

Note: Y and Z are typically small compared to node costs.

---

## Related Documentation

- [Module README - Deployment Mode Comparison](README.md#deployment-mode-comparison)
- [Module README - High Availability Section](README.md#high-availability)
- [AWS ElastiCache Multi-AZ](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/AutomaticFailover.html)
