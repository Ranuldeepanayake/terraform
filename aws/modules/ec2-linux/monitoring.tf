# Create a retained CloudWatch log group when log shipping is enabled.
resource "aws_cloudwatch_log_group" "this" {
  count             = var.enable_cloudwatch_logging ? 1 : 0
  name              = "${var.instance_name}-${local.random_suffix}"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.cloudwatch_log_kms_key_id

  tags = merge(
    var.tags,
    {
      ResourceType = "cloudwatch-log-group"
      Name         = "${var.instance_name}-${local.random_suffix}"
    }
  )
}

# Create an SNS topic and email subscriptions only when recipients are supplied.
resource "aws_sns_topic" "alarm_email" {
  count = length(var.alarm_email_addresses) > 0 ? 1 : 0

  name = "${var.instance_name}-${local.random_suffix}"

  tags = merge(
    var.tags,
    {
      ResourceType = "sns-topic"
      Name         = "${var.instance_name}-${local.random_suffix}"
    }
  )
}

# Subscribe each caller-supplied address to the alarm topic.
resource "aws_sns_topic_subscription" "alarm_email" {
  for_each = toset(var.alarm_email_addresses)

  topic_arn = aws_sns_topic.alarm_email[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# Alarm on high EC2 CPU utilization.
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count               = local.alarms.cpu_enabled ? 1 : 0
  alarm_name          = "${var.instance_name}-high-cpu"
  alarm_description   = "EC2 CPU utilization exceeded the configured threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarms.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarms.period
  statistic           = "Average"
  threshold           = var.alarms.cpu_threshold
  treat_missing_data  = var.alarms.treat_missing_data
  alarm_actions       = local.effective_alarm_actions
  ok_actions          = var.alarm_ok_actions

  dimensions = { InstanceId = aws_instance.ec2.id }

  tags = merge(
    var.tags,
    {
      ResourceType = "cloudwatch-alarm"
      Name         = "${var.instance_name}-high-cpu"
    }
  )
}

# Alarm on high memory utilization reported by the CloudWatch Agent.
resource "aws_cloudwatch_metric_alarm" "memory" {
  count               = local.alarms.memory_enabled ? 1 : 0
  alarm_name          = "${var.instance_name}-high-memory"
  alarm_description   = "EC2 memory utilization exceeded the configured threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarms.evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarms.period
  statistic           = "Average"
  threshold           = var.alarms.memory_threshold
  treat_missing_data  = var.alarms.treat_missing_data
  alarm_actions       = local.effective_alarm_actions
  ok_actions          = var.alarm_ok_actions

  dimensions = { InstanceId = aws_instance.ec2.id }

  tags = merge(
    var.tags,
    {
      ResourceType = "cloudwatch-alarm"
      Name         = "${var.instance_name}-high-memory"
    }
  )
}

# Alarm on high filesystem utilization reported by the CloudWatch Agent.
resource "aws_cloudwatch_metric_alarm" "disk_space" {
  count               = local.alarms.disk_space_enabled ? 1 : 0
  alarm_name          = "${var.instance_name}-high-disk-use"
  alarm_description   = "EC2 disk space utilization exceeded the configured threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarms.evaluation_periods
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = var.alarms.period
  statistic           = "Average"
  threshold           = var.alarms.disk_space_threshold
  treat_missing_data  = var.alarms.treat_missing_data
  alarm_actions       = local.effective_alarm_actions
  ok_actions          = var.alarm_ok_actions

  dimensions = { InstanceId = aws_instance.ec2.id }

  tags = merge(
    var.tags,
    {
      ResourceType = "cloudwatch-alarm"
      Name         = "${var.instance_name}-high-disk-use"
    }
  )
}

# Alarm on EC2 network bytes received during each alarm period.
resource "aws_cloudwatch_metric_alarm" "network_in" {
  count               = local.alarms.network_in_enabled ? 1 : 0
  alarm_name          = "${var.instance_name}-high-network-in"
  alarm_description   = "EC2 inbound network traffic exceeded the configured bytes-per-period threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarms.evaluation_periods
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = var.alarms.period
  statistic           = "Sum"
  threshold           = var.alarms.network_in_threshold
  treat_missing_data  = var.alarms.treat_missing_data
  alarm_actions       = local.effective_alarm_actions
  ok_actions          = var.alarm_ok_actions

  dimensions = { InstanceId = aws_instance.ec2.id }

  tags = merge(
    var.tags,
    {
      ResourceType = "cloudwatch-alarm"
      Name         = "${var.instance_name}-high-network-in"
    }
  )
}

# Alarm on EC2 network bytes sent during each alarm period.
resource "aws_cloudwatch_metric_alarm" "network_out" {
  count               = local.alarms.network_out_enabled ? 1 : 0
  alarm_name          = "${var.instance_name}-high-network-out"
  alarm_description   = "EC2 outbound network traffic exceeded the configured bytes-per-period threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarms.evaluation_periods
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = var.alarms.period
  statistic           = "Sum"
  threshold           = var.alarms.network_out_threshold
  treat_missing_data  = var.alarms.treat_missing_data
  alarm_actions       = local.effective_alarm_actions
  ok_actions          = var.alarm_ok_actions

  dimensions = { InstanceId = aws_instance.ec2.id }

  tags = merge(
    var.tags,
    {
      ResourceType = "cloudwatch-alarm"
      Name         = "${var.instance_name}-high-network-out"
    }
  )
}

# Alarm on read/write operations for each configured additional EBS volume.
resource "aws_cloudwatch_metric_alarm" "ebs_io" {
  for_each = local.alarms.ebs_io_enabled ? {
    for alarm in local.ebs_io_alarm_pairs : alarm.key => alarm
  } : {}

  alarm_name          = "${var.instance_name}-${each.key}-high"
  alarm_description   = "${each.value.metric_name} exceeded the configured EBS operations threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarms.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = "AWS/EBS"
  period              = var.alarms.period
  statistic           = "Sum"
  threshold           = var.alarms.ebs_io_threshold
  treat_missing_data  = var.alarms.treat_missing_data
  alarm_actions       = local.effective_alarm_actions
  ok_actions          = var.alarm_ok_actions

  dimensions = { VolumeId = each.value.volume_id }

  tags = merge(
    var.tags,
    {
      ResourceType = "cloudwatch-alarm"
      Name         = "${var.instance_name}-${each.key}-high"
    }
  )
}

# Create caller-defined CloudWatch metric alarms.
resource "aws_cloudwatch_metric_alarm" "additional" {
  for_each = var.additional_alarms

  alarm_name          = coalesce(each.value.alarm_name, "${var.instance_name}-${each.key}")
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  unit                = each.value.unit
  treat_missing_data  = each.value.treat_missing_data
  actions_enabled     = each.value.actions_enabled
  alarm_actions = distinct(concat(
    coalesce(each.value.alarm_actions, var.alarm_actions),
    local.email_alarm_topic_arn == null ? [] : [local.email_alarm_topic_arn],
  ))
  ok_actions = coalesce(each.value.ok_actions, var.alarm_ok_actions)

  dimensions = {
    for name, value in each.value.dimensions :
    name => value == "__EC2_INSTANCE_ID__" ? aws_instance.ec2.id : value
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "cloudwatch-alarm"
      Name         = coalesce(each.value.alarm_name, "${var.instance_name}-${each.key}")
    }
  )
}