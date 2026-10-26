# =============================================================================
# Locals
# =============================================================================

locals {
  default_egress_rules = {
    allow_all = {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  notification_topic_arn = var.create_sns_topic ? aws_sns_topic.alerts[0].arn : var.notification_topic_arn
}

# =============================================================================
# SNS Topic for Alerts
#
# Creates an optional SNS topic for ElastiCache notifications and alarm alerts.
# Email subscriptions are created for all provided email addresses.
# =============================================================================

resource "aws_sns_topic" "alerts" {
  count = var.create_sns_topic ? 1 : 0

  name              = "${var.cluster_id}-elasticache-alerts"
  display_name      = "ElastiCache Alerts for ${var.cluster_id}"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-sns-topic"
    }
  )
}

resource "aws_sns_topic_subscription" "alerts_email" {
  for_each = var.create_sns_topic ? toset(var.alert_email_addresses) : toset([])

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# =============================================================================
# ElastiCache Subnet Group
#
# Creates a subnet group to specify the subnets where the cluster will run.
# The VPC and subnets must already exist; they are not created by this module.
# =============================================================================

resource "aws_elasticache_subnet_group" "this" {
  # Use a provided name or generate one with a prefix for auto-replacement during updates
  name        = var.subnet_group_name
  description = "Subnet group for ElastiCache Valkey cluster ${var.cluster_id}"

  # Use the provided subnet IDs for cluster deployment
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-subnet-group"
    }
  )

  lifecycle {
    precondition {
      condition     = var.multi_az_enabled ? length(var.subnet_ids) >= 2 : true
      error_message = "Multi-AZ deployments require at least 2 subnets in different AZs."
    }
  }
}

# =============================================================================
# Security Group
#
# Creates a security group for the ElastiCache cluster if specified.
# Allows inbound traffic from specified security groups and CIDR blocks.
# =============================================================================

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name_prefix = "${var.cluster_id}-"
  description = "Security group for ElastiCache Valkey cluster ${var.cluster_id}"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-security-group"
    }
  )
}

# Create ingress rules for the security group
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.create_security_group ? var.security_group_ingress_rules : {}

  security_group_id = aws_security_group.this[0].id

  description                  = try(each.value.description, null)
  from_port                    = each.value.protocol == "-1" ? null : each.value.from_port
  to_port                      = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol                  = each.value.protocol
  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-sg-rule-ingress"
    }
  )
}

# Create egress rules for the security group
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = var.create_security_group ? (length(var.security_group_egress_rules) > 0 ? var.security_group_egress_rules : local.default_egress_rules) : {}

  security_group_id = aws_security_group.this[0].id

  description                  = try(each.value.description, null)
  from_port                    = each.value.protocol == "-1" ? null : each.value.from_port
  to_port                      = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol                  = each.value.protocol
  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-sg-rule-egress"
    }
  )
}

# =============================================================================
# Parameter Group
#
# Creates a custom parameter group if none is specified.
# Allows fine-tuning of Valkey behavior through parameters.
# =============================================================================

resource "aws_elasticache_parameter_group" "this" {
  count = var.parameter_group_name == null && var.deployment_mode == "provisioned" ? 1 : 0

  family      = var.parameter_group_family
  name        = "${var.cluster_id}-${substr(md5(aws_elasticache_subnet_group.this.id), 0, 8)}"
  description = "Custom parameter group for Valkey cluster ${var.cluster_id}"

  lifecycle {
    precondition {
      condition     = var.parameter_group_family != null
      error_message = "parameter_group_family is required when creating a new parameter group (when parameter_group_name is null and deployment_mode is provisioned). Specify the family matching your engine version (e.g., 'valkey8' for Valkey 8.x)."
    }
  }

  # Apply custom parameters if provided
  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# CloudWatch Log Groups
#
# Creates log groups for Valkey slow-log and engine-log with retention policies.
# =============================================================================

resource "aws_cloudwatch_log_group" "slow_log" {
  count = var.cloudwatch_log_enabled && var.create_log_groups ? 1 : 0

  name              = var.slow_log_group_name != null ? var.slow_log_group_name : "/aws/elasticache/valkey/${var.cluster_id}/slow-log"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-log-group"
    }
  )
}

resource "aws_cloudwatch_log_group" "engine_log" {
  count = var.cloudwatch_log_enabled && var.create_log_groups ? 1 : 0

  name              = var.engine_log_group_name != null ? var.engine_log_group_name : "/aws/elasticache/valkey/${var.cluster_id}/engine-log"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-log-group"
    }
  )
}

# =============================================================================
# CloudWatch Alarms
#
# Creates alarms for CPU, evictions, connections, and memory usage.
# Alarms send notifications to the SNS topic if configured.
# =============================================================================

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.create_alarms && var.deployment_mode == "provisioned" ? 1 : 0

  alarm_name          = "${var.cluster_id}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  alarm_description   = "Alert when ElastiCache CPU utilization exceeds ${var.alarm_cpu_threshold}%"
  alarm_actions       = local.notification_topic_arn != null ? [local.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.provisioned[0].id
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "evictions" {
  count = var.create_alarms && var.deployment_mode == "provisioned" ? 1 : 0

  alarm_name          = "${var.cluster_id}-high-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alarm_eviction_threshold
  alarm_description   = "Alert when evictions exceed ${var.alarm_eviction_threshold} per minute"
  alarm_actions       = local.notification_topic_arn != null ? [local.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.provisioned[0].id
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "current_connections" {
  count = var.create_alarms && var.deployment_mode == "provisioned" ? 1 : 0

  alarm_name          = "${var.cluster_id}-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_connection_threshold
  alarm_description   = "Alert when client connections exceed ${var.alarm_connection_threshold}"
  alarm_actions       = local.notification_topic_arn != null ? [local.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.provisioned[0].id
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_memory_usage_percentage" {
  count = var.create_alarms && var.deployment_mode == "provisioned" ? 1 : 0

  alarm_name          = "${var.cluster_id}-high-memory-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_memory_threshold
  alarm_description   = "Alert when memory usage exceeds ${var.alarm_memory_threshold}%"
  alarm_actions       = local.notification_topic_arn != null ? [local.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.provisioned[0].id
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "engine_cpu_utilization" {
  count = var.create_alarms && var.deployment_mode == "provisioned" ? 1 : 0

  alarm_name          = "${var.cluster_id}-high-engine-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  alarm_description   = "Alert when engine CPU utilization exceeds ${var.alarm_cpu_threshold}%"
  alarm_actions       = local.notification_topic_arn != null ? [local.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.provisioned[0].id
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "custom" {
  for_each = var.deployment_mode == "provisioned" ? var.custom_alarms : {}

  alarm_name          = "${var.cluster_id}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description != null ? each.value.alarm_description : "Custom alarm: ${each.key}"
  alarm_actions       = local.notification_topic_arn != null ? [local.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.provisioned[0].id
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-alarm"
    }
  )
}

# =============================================================================
# AWS Secrets Manager Secret for Auth Token
#
# Stores the Valkey authentication token securely in Secrets Manager.
# Created only when auth_token_enabled is true.
# =============================================================================

resource "aws_secretsmanager_secret" "auth_token" {
  count = var.auth_token_enabled ? 1 : 0

  name_prefix             = var.auth_secret_name != null ? "" : "${var.cluster_id}-valkey-auth-"
  name                    = var.auth_secret_name != null ? var.auth_secret_name : null
  description             = "Valkey authentication token for cluster ${var.cluster_id}"
  recovery_window_in_days = 7

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-auth-secret"
    }
  )
}

resource "aws_secretsmanager_secret_version" "auth_token" {
  count = var.auth_token_enabled ? 1 : 0

  secret_id     = aws_secretsmanager_secret.auth_token[0].id
  secret_string = var.auth_token
}

# =============================================================================
# ElastiCache Provisioned Valkey Replication Group
#
# Creates a provisioned Valkey replication group with support for
# single-node, multi-node, Multi-AZ, automatic failover, and auth tokens.
# =============================================================================

resource "aws_elasticache_replication_group" "provisioned" {
  count = var.deployment_mode == "provisioned" ? 1 : 0

  replication_group_id       = var.cluster_id
  description = "Valkey replication group for ${var.cluster_id}"

  # Engine configuration
  engine         = "valkey"
  engine_version = var.engine_version

  # Compute and storage sizing
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes

  # Networking
  subnet_group_name = aws_elasticache_subnet_group.this.name
  port              = var.port

  # Security groups
  security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids

  # Parameter group configuration
  parameter_group_name = var.parameter_group_name != null ? var.parameter_group_name : aws_elasticache_parameter_group.this[0].name

  # High availability and failover
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  # Encryption configuration
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  kms_key_id                 = var.at_rest_encryption_kms_key_id
  auth_token                 = var.auth_token_enabled ? var.auth_token : null
  transit_encryption_enabled = var.transit_encryption_enabled
  transit_encryption_mode    = var.transit_encryption_enabled ? var.transit_encryption_mode : null

  # Logging and monitoring
  dynamic "log_delivery_configuration" {
    for_each = var.create_log_groups && var.cloudwatch_log_enabled ? {
      "slow-log" = {
        log_format                = "json"
        cloudwatch_log_group_name = aws_cloudwatch_log_group.slow_log[0].name
      }
      "engine-log" = {
        log_format                = "json"
        cloudwatch_log_group_name = aws_cloudwatch_log_group.engine_log[0].name
      }
    } : {}
    content {
      destination      = log_delivery_configuration.value.cloudwatch_log_group_name
      destination_type = "cloudwatch-logs"
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.key
    }
  }

  # Snapshots and backup configuration
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_retention_limit > 0 ? var.snapshot_window : null

  # Maintenance and notifications
  maintenance_window     = var.maintenance_window
  notification_topic_arn = local.notification_topic_arn

  # Apply changes
  apply_immediately = var.apply_immediately

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-valkey-replication-group"
    }
  )

  depends_on = [aws_elasticache_subnet_group.this]

  lifecycle {
    precondition {
      condition     = var.auth_token_enabled ? (var.auth_token != null && length(var.auth_token) >= 16 && length(var.auth_token) <= 128) : true
      error_message = "auth_token must be between 16 and 128 characters when auth_token_enabled is true."
    }

    precondition {
      condition     = var.automatic_failover_enabled ? (var.multi_az_enabled || var.num_cache_nodes > 1) : true
      error_message = "automatic_failover_enabled requires either multi_az_enabled=true or num_cache_nodes > 1."
    }

    precondition {
      condition     = var.snapshot_retention_limit > 0 ? var.num_cache_nodes == 1 : true
      error_message = "Snapshots are only supported for single-node clusters (num_cache_nodes=1)."
    }

    precondition {
      condition     = var.create_security_group ? var.vpc_id != null : true
      error_message = "vpc_id is required when create_security_group is true."
    }

    precondition {
      condition     = !var.create_alarms || (var.create_sns_topic || var.notification_topic_arn != null)
      error_message = "When create_alarms is true, either create_sns_topic must be true or notification_topic_arn must be provided."
    }
  }
}

# =============================================================================
# ElastiCache Serverless Valkey Cache
#
# Creates a serverless Valkey cache with automatic scaling and built-in HA.
# No need to manage nodes; capacity scales automatically based on demand.
# =============================================================================

resource "aws_elasticache_serverless_cache" "serverless" {
  count = var.deployment_mode == "serverless" ? 1 : 0

  engine = "valkey"
  name   = var.cluster_id

  cache_usage_limits {
    data_storage {
      maximum = var.serverless_cache_size
      unit    = "GB"
    }
  }

  # Networking
  security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids
  subnet_ids         = var.subnet_ids

  # Encryption configuration
  kms_key_id = var.at_rest_encryption_kms_key_id

  tags = merge(
    var.tags,
    {
      ResourceType = "elasticache-valkey-serverless"
    }
  )

  lifecycle {
    precondition {
      condition     = var.create_security_group ? var.vpc_id != null : true
      error_message = "vpc_id is required when create_security_group is true."
    }
  }
}

# =============================================================================
# Route53 DNS Record (Optional)
#
# Creates a Route53 CNAME record pointing to the ElastiCache endpoint.
# If route53_record_name is not provided, uses the cluster_id as the DNS record name.
# =============================================================================

locals {
  # Use provided name or default to cluster_id (which is part of the endpoint)
  route53_dns_name = var.route53_record_name != null ? var.route53_record_name : var.cluster_id
}

resource "aws_route53_record" "valkey" {
  count = var.create_route53_record ? 1 : 0

  zone_id = var.route53_zone_id
  name    = local.route53_dns_name
  type    = "CNAME"
  ttl     = var.route53_ttl
  records = [var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].primary_endpoint_address : aws_elasticache_serverless_cache.serverless[0].endpoint[0].address]

  lifecycle {
    precondition {
      condition     = var.route53_zone_id != null
      error_message = "route53_zone_id is required when create_route53_record is true."
    }
  }
}
