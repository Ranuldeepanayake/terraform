# Create a distinct access-log group for each stage that enables access logging.
resource "aws_cloudwatch_log_group" "api_gateway" {
  for_each = {
    for name, settings in local.stage_logging : name => settings
    if settings.enabled
  }

  name              = each.value.log_group_name
  retention_in_days = each.value.retention_in_days
}

# Stage settings are independent even though routes and integrations belong to the shared API.
resource "aws_apigatewayv2_stage" "this" {
  for_each = var.stages

  api_id          = aws_apigatewayv2_api.this.id
  name            = each.key
  auto_deploy     = each.value.auto_deploy
  deployment_id   = each.value.auto_deploy ? null : aws_apigatewayv2_deployment.this[each.key].id
  description     = each.value.description
  stage_variables = each.value.stage_variables
  tags            = each.value.tags

  # API Gateway access logs are configured independently for each stage.
  dynamic "access_log_settings" {
    for_each = local.stage_logging[each.key].enabled ? [local.stage_logging[each.key]] : []

    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[each.key].arn
      format          = access_log_settings.value.format
    }
  }

  # Default route settings provide per-stage throttling, metrics, and execution logging.
  dynamic "default_route_settings" {
    for_each = (
      coalesce(each.value.throttling.enabled, false) ||
      coalesce(each.value.detailed_metrics_enabled, false) ||
      each.value.logging_level != null ||
      each.value.data_trace_enabled != null
    ) ? [each.value] : []

    content {
      data_trace_enabled       = default_route_settings.value.data_trace_enabled
      detailed_metrics_enabled = coalesce(default_route_settings.value.detailed_metrics_enabled, false)
      logging_level            = default_route_settings.value.logging_level
      throttling_rate_limit = coalesce(
        default_route_settings.value.throttling.enabled,
        false
      ) ? coalesce(default_route_settings.value.throttling.rate_limit, 100) : null
      throttling_burst_limit = coalesce(
        default_route_settings.value.throttling.enabled,
        false
      ) ? coalesce(default_route_settings.value.throttling.burst_limit, 200) : null
    }
  }

  # Optional route-level overrides take precedence over this stage's default route settings.
  dynamic "route_settings" {
    for_each = each.value.route_settings
    iterator = route_setting

    content {
      route_key                = route_setting.key
      data_trace_enabled       = route_setting.value.data_trace_enabled
      detailed_metrics_enabled = route_setting.value.detailed_metrics_enabled
      logging_level            = route_setting.value.logging_level
      throttling_rate_limit    = route_setting.value.throttling_rate_limit
      throttling_burst_limit   = route_setting.value.throttling_burst_limit
    }
  }
}

# With auto_deploy disabled, changing the trigger explicitly publishes a new snapshot for that stage.
resource "aws_apigatewayv2_deployment" "this" {
  for_each = {
    for name, stage in var.stages : name => stage
    if !stage.auto_deploy
  }

  api_id = aws_apigatewayv2_api.this.id
  triggers = {
    redeployment = each.value.deployment_trigger
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_apigatewayv2_integration.lambda,
    aws_apigatewayv2_route.this,
    aws_apigatewayv2_route.default
  ]
}