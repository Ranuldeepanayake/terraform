# Reads the active AWS partition for constructing policy ARNs.
data "aws_partition" "current" {}

# Collects shared resource names and derived settings.
locals {
  log_group_prefix = var.deployment_mode == "multi_az_cluster" ? "cluster" : "instance"

  monitoring_role_arn = var.monitoring_interval == 0 ? null : (
    var.create_monitoring_role ? aws_iam_role.rds_enhanced_monitoring[0].arn : var.monitoring_role_arn
  )

  effective_parameter_group_name = length(var.postgres_parameters) == 0 ? var.parameter_group_name : (
    var.deployment_mode == "multi_az_cluster" ? aws_rds_cluster_parameter_group.this[0].name : aws_db_parameter_group.this[0].name
  )

  primary_alarm_dimensions = var.deployment_mode == "multi_az_cluster" ? {
    DBClusterIdentifier = var.identifier
    } : {
    DBInstanceIdentifier = var.identifier
  }

  cloudwatch_alarms_by_name = {
    for alarm in var.cloudwatch_alarms : alarm.alarm_name => alarm
  }
}

# Creates the IAM role used by RDS Enhanced Monitoring.
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 && var.create_monitoring_role ? 1 : 0

  name_prefix = "${substr(var.identifier, 0, 30)}-monitoring-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(
    var.tags,
    {
      ResourceType = "iam-role"
    }
  )
}

# Attaches the AWS-managed Enhanced Monitoring policy to the role.
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 && var.create_monitoring_role ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Creates a PostgreSQL parameter group when custom parameters are supplied.
resource "aws_db_parameter_group" "this" {
  count = length(var.postgres_parameters) > 0 && var.deployment_mode == "db_instance" ? 1 : 0

  name_prefix = "${var.identifier}-"
  family      = var.parameter_group_family
  description = "Custom PostgreSQL parameter group for ${var.identifier}"

  dynamic "parameter" {
    for_each = var.postgres_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "rds-parameter-group"
    }
  )
}

# Creates the cluster parameter group for custom Multi-AZ cluster settings.
resource "aws_rds_cluster_parameter_group" "this" {
  count = length(var.postgres_parameters) > 0 && var.deployment_mode == "multi_az_cluster" ? 1 : 0

  name_prefix = "${var.identifier}-"
  family      = var.parameter_group_family
  description = "Custom PostgreSQL cluster parameter group for ${var.identifier}"

  dynamic "parameter" {
    for_each = var.postgres_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "rds-cluster-parameter-group"
    }
  )
}

# Creates retained CloudWatch log groups for selected RDS log exports.
resource "aws_cloudwatch_log_group" "rds" {
  for_each = toset(var.cloudwatch_log_exports)

  name              = "/aws/rds/${local.log_group_prefix}/${var.identifier}/${each.value}"
  retention_in_days = var.cloudwatch_log_retention_in_days

  tags = merge(
    var.tags,
    {
      ResourceType = "cloudwatch-log-group"
    }
  )
}

# Creates configured same-region read replicas of the primary DB instance.
resource "aws_db_instance" "read_replica" {
  for_each = var.deployment_mode == "db_instance" ? {
    for replica in var.read_replicas : replica.identifier => replica
  } : {}

  identifier          = each.value.identifier
  replicate_source_db = aws_db_instance.this[0].identifier
  instance_class      = each.value.instance_class
  availability_zone   = each.value.availability_zone
  publicly_accessible = each.value.publicly_accessible

  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.create_security_group ? [
    aws_security_group.this[0].id
  ] : var.security_group_ids

  copy_tags_to_snapshot = var.copy_tags_to_snapshot
  monitoring_interval   = var.monitoring_interval
  monitoring_role_arn   = local.monitoring_role_arn
  parameter_group_name  = local.effective_parameter_group_name

  tags = merge(
    var.tags,
    {
      ResourceType = "rds-read-replica"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.rds_enhanced_monitoring,
    aws_db_instance.this
  ]
}

# Exports a configured RDS snapshot to S3.
resource "aws_rds_export_task" "snapshot" {
  count = var.snapshot_export_configuration == null ? 0 : 1

  export_task_identifier = var.snapshot_export_configuration.export_task_identifier
  source_arn             = var.snapshot_export_configuration.source_arn
  s3_bucket_name         = var.snapshot_export_configuration.s3_bucket_name
  iam_role_arn           = var.snapshot_export_configuration.iam_role_arn
  kms_key_id             = var.snapshot_export_configuration.kms_key_id
  s3_prefix              = var.snapshot_export_configuration.s3_prefix
  export_only            = var.snapshot_export_configuration.export_only
}

# Creates CloudWatch metric alarms for the primary DB instance.
resource "aws_cloudwatch_metric_alarm" "rds" {
  for_each = local.cloudwatch_alarms_by_name

  alarm_name          = each.value.alarm_name
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions
  treat_missing_data  = each.value.treat_missing_data
  actions_enabled     = each.value.actions_enabled

  dimensions = merge(
    each.value.dimensions,
    local.primary_alarm_dimensions
  )
}
