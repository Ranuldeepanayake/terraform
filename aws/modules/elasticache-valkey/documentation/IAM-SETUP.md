# IAM Setup for ElastiCache Valkey Module

This guide covers the IAM roles and permissions required for ElastiCache to function correctly, especially for logging to CloudWatch.

## Service-Linked Role (Automatic)

ElastiCache requires an **AWS service-linked role** (`AWSServiceRoleForElastiCache`) to write logs to CloudWatch Logs. This role is **created automatically** by AWS on first use.

### Verify Service-Linked Role Exists

```bash
aws iam get-role --role-name AWSServiceRoleForElastiCache
```

### Explicitly Create Service-Linked Role (if needed)

```hcl
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}
```

The service-linked role includes these permissions automatically:
- `logs:PutLogEvents` - Write to CloudWatch Logs
- `logs:CreateLogGroup` - Create log groups
- `logs:CreateLogStream` - Create log streams

---

## Terraform Execution Role

Your Terraform runner (CI/CD pipeline, developer machine, etc.) needs an IAM role with permissions to manage ElastiCache resources.

### Minimal Policy (Development Only)

Use this for development/testing environments with no encryption:

```hcl
resource "aws_iam_policy" "terraform_elasticache_minimal" {
  name        = "terraform-elasticache-minimal"
  description = "Minimal permissions for Terraform to manage ElastiCache"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ElastiCacheCluster"
        Effect = "Allow"
        Action = [
          "elasticache:CreateCacheCluster",
          "elasticache:DeleteCacheCluster",
          "elasticache:DescribeCacheClusters",
          "elasticache:ModifyCacheCluster"
        ]
        Resource = "*"
      },
      {
        Sid    = "ElastiCacheParameterGroup"
        Effect = "Allow"
        Action = [
          "elasticache:CreateCacheParameterGroup",
          "elasticache:DeleteCacheParameterGroup",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:ModifyCacheParameterGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "ElastiCacheSubnetGroup"
        Effect = "Allow"
        Action = [
          "elasticache:CreateCacheSubnetGroup",
          "elasticache:DeleteCacheSubnetGroup",
          "elasticache:DescribeCacheSubnetGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2SecurityGroups"
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      }
    ]
  })
}
```

### Standard Policy (Production Without Encryption)

For production use without encryption or logging:

```hcl
resource "aws_iam_policy" "terraform_elasticache_standard" {
  name        = "terraform-elasticache-standard"
  description = "Standard permissions for Terraform to manage ElastiCache"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ElastiCacheCluster"
        Effect = "Allow"
        Action = [
          "elasticache:CreateCacheCluster",
          "elasticache:CreateServerlessCache",
          "elasticache:DeleteCacheCluster",
          "elasticache:DeleteServerlessCache",
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeServerlessCaches",
          "elasticache:ModifyCacheCluster",
          "elasticache:ModifyServerlessCache"
        ]
        Resource = "*"
      },
      {
        Sid    = "ElastiCacheParameterGroup"
        Effect = "Allow"
        Action = [
          "elasticache:CreateCacheParameterGroup",
          "elasticache:DeleteCacheParameterGroup",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:ModifyCacheParameterGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "ElastiCacheSubnetGroup"
        Effect = "Allow"
        Action = [
          "elasticache:CreateCacheSubnetGroup",
          "elasticache:DeleteCacheSubnetGroup",
          "elasticache:DescribeCacheSubnetGroups",
          "elasticache:ModifyCacheSubnetGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2SecurityGroups"
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:*valkey*"
      },
      {
        Sid    = "SNS"
        Effect = "Allow"
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:SetTopicAttributes",
          "sns:Subscribe"
        ]
        Resource = "arn:aws:sns:*:*:*elasticache*"
      }
    ]
  })
}
```

### Comprehensive Policy (Production With Logging & Encryption)

For production use with full logging and encryption support:

```hcl
resource "aws_iam_policy" "terraform_elasticache_comprehensive" {
  name        = "terraform-elasticache-comprehensive"
  description = "Comprehensive permissions for Terraform to manage ElastiCache with logging and encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ElastiCacheCluster"
        Effect = "Allow"
        Action = [
          "elasticache:CreateCacheCluster",
          "elasticache:CreateServerlessCache",
          "elasticache:DeleteCacheCluster",
          "elasticache:DeleteServerlessCache",
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeServerlessCaches",
          "elasticache:ModifyCacheCluster",
          "elasticache:ModifyServerlessCache"
        ]
        Resource = "*"
      },
      {
        Sid    = "ElastiCacheParameterGroup"
        Effect = "Allow"
        Action = [
          "elasticache:CreateCacheParameterGroup",
          "elasticache:DeleteCacheParameterGroup",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:ModifyCacheParameterGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "ElastiCacheSubnetGroup"
        Effect = "Allow"
        Action = [
          "elasticache:CreateCacheSubnetGroup",
          "elasticache:DeleteCacheSubnetGroup",
          "elasticache:DescribeCacheSubnetGroups",
          "elasticache:ModifyCacheSubnetGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2SecurityGroups"
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/elasticache/*"
      },
      {
        Sid    = "CloudWatchAlarms"
        Effect = "Allow"
        Action = [
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:*valkey*"
      },
      {
        Sid    = "SNS"
        Effect = "Allow"
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:SetTopicAttributes",
          "sns:Subscribe"
        ]
        Resource = "arn:aws:sns:*:*:*elasticache*"
      },
      {
        Sid    = "KMSEncryption"
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:ListAliases",
          "kms:ListGrants",
          "kms:RetireGrant"
        ]
        Resource = "arn:aws:kms:*:*:key/*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "elasticache.*.amazonaws.com"
          }
        }
      }
    ]
  })
}
```

---

## Complete Setup Example

Here's a complete example showing how to set up IAM roles and use them with the ElastiCache module:

```hcl
# Create Terraform execution role
resource "aws_iam_role" "terraform_elasticache" {
  name               = "terraform-elasticache-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
          # Or your CI/CD service, e.g., "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach comprehensive policy
resource "aws_iam_role_policy_attachment" "terraform_elasticache" {
  role       = aws_iam_role.terraform_elasticache.name
  policy_arn = aws_iam_policy.terraform_elasticache_comprehensive.arn
}

# Create service-linked role for ElastiCache
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

# Now use the module with logging enabled
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

  # Logging will work because service-linked role exists
  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 30

  # Encryption
  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn
  transit_encryption_enabled    = true
  transit_encryption_mode       = "required"

  # Monitoring
  create_sns_topic      = true
  alert_email_addresses = ["ops@company.com"]

  # Depends on service-linked role
  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
  }
}

output "cache_endpoint" {
  value = module.valkey_prod.primary_endpoint
}
```

---

## Minimal Complete Caller Example with IAM

```hcl
# Minimal IAM setup for ElastiCache logging to work

resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}

resource "aws_kms_key" "cache" {
  description             = "KMS key for ElastiCache"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

module "valkey_single_node" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = "prod-cache"
  engine_version  = "8.0"
  node_type       = "cache.m7g.large"
  num_cache_nodes = 1

  subnet_ids = [aws_subnet.private.id]
  vpc_id     = aws_vpc.main.id

  # These require the service-linked role to exist
  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 7

  # Encryption
  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = aws_kms_key.cache.arn
  transit_encryption_enabled    = true

  depends_on = [aws_iam_service_linked_role.elasticache]

  tags = {
    Environment = "production"
  }
}

output "cache_endpoint" {
  value = module.valkey_single_node.primary_endpoint
}
```

---

## Troubleshooting

### Error: Service-Linked Role Not Found

**Error Message**:
```
Error creating cache cluster: AccessDenied: User: arn:aws:iam::123456789012:user/terraform is not authorized to perform: elasticache:CreateCacheCluster because no service-linked role exists...
```

**Solution**: Create the service-linked role explicitly:

```hcl
resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
}
```

Then add `depends_on = [aws_iam_service_linked_role.elasticache]` to your module.

### Error: Missing CloudWatch Logs Permission

**Error Message**:
```
Error modifying cache cluster: InvalidParameterCombination: 
Logs can't be enabled for this parameter group
```

**Solution**: Ensure Terraform role has these permissions:

```hcl
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutRetentionPolicy"
  ],
  "Resource": "arn:aws:logs:*:*:log-group:/aws/elasticache/*"
}
```

### Error: Missing KMS Permissions

**Error Message**:
```
AccessDenied: User is not authorized to perform: kms:Encrypt on resource...
```

**Solution**: Add KMS permissions to Terraform role:

```hcl
{
  "Effect": "Allow",
  "Action": [
    "kms:Decrypt",
    "kms:DescribeKey",
    "kms:Encrypt",
    "kms:GenerateDataKey"
  ],
  "Resource": "arn:aws:kms:*:*:key/*"
}
```

---

## See Also

- [Provisioned Single-Instance Example](./PROVISIONED-SINGLE-INSTANCE.md)
- [Provisioned Multi-AZ Example](./PROVISIONED-MULTI-AZ.md)
- [Serverless Example](./SERVERLESS.md)
- [Encryption Configuration](./ENCRYPTION.md)
- [AWS IAM Documentation](https://docs.aws.amazon.com/IAM/)
