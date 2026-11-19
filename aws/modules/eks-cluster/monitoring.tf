# CloudWatch alarms for standard EKS node and control-plane metrics. Alarms and
# their metric collection are gated by the caller's alarms.enabled setting.
# Create a cluster-specific standard topic unless the caller supplies one.
resource "aws_sns_topic" "alarm_email" {
  count = var.alarms.enabled && var.alarm_sns_topic_arn == null ? 1 : 0

  name = coalesce(var.alarm_sns_topic_name, "${var.cluster_name}-alerts")

  tags = merge(var.tags, {
    ResourceType = "cloudwatch-alarm-topic"
    Name         = coalesce(var.alarm_sns_topic_name, "${var.cluster_name}-alerts")
  })
}

# Subscribe caller-supplied addresses to the selected topic. Each recipient
# must confirm the email SNS sends before notifications are delivered.
resource "aws_sns_topic_subscription" "alarm_email" {
  for_each = var.alarms.enabled ? toset(var.alarm_email_addresses) : toset([])

  topic_arn = local.alarm_topic_arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "builtin" {
  for_each = var.alarms.enabled ? local.builtin_alarms : {}

  alarm_name          = "${var.cluster_name}-${each.key}"
  alarm_description   = each.value.description
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarms.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = var.alarms.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  treat_missing_data  = var.alarms.treat_missing_data
  alarm_actions       = local.effective_alarm_actions
  ok_actions          = var.alarm_ok_actions

  dimensions = { ClusterName = aws_eks_cluster.main.name }

  tags = merge(var.tags, {
    ResourceType = "cloudwatch-alarm"
    Name         = "${var.cluster_name}-${each.key}"
  })
}

# Additional metric alarms follow the EC2 module's caller-defined alarm shape.
resource "aws_cloudwatch_metric_alarm" "additional" {
  for_each = var.alarms.enabled ? var.additional_alarms : {}

  alarm_name          = coalesce(each.value.alarm_name, "${var.cluster_name}-${each.key}")
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
    local.alarm_topic_actions,
  ))
  ok_actions = coalesce(each.value.ok_actions, var.alarm_ok_actions)
  dimensions = each.value.dimensions

  tags = merge(var.tags, {
    ResourceType = "cloudwatch-alarm"
    Name         = coalesce(each.value.alarm_name, "${var.cluster_name}-${each.key}")
  })
}
