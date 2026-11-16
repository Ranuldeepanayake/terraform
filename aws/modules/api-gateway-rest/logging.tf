resource "aws_cloudwatch_log_group" "api_gateway" {
  for_each = {
    for name, settings in local.stage_logging : name => settings
    if settings.enabled
  }

  name              = each.value.log_group_name
  retention_in_days = each.value.retention_in_days
}

# All stages share one deployment snapshot. Changing deployment_trigger forces create_before_destroy,
# publishing a new snapshot without downtime.
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = var.deployment_trigger
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.lambda,
    aws_api_gateway_method.options,
    aws_api_gateway_integration.options,
    aws_api_gateway_integration_response.options,
  ]
}

resource "aws_api_gateway_stage" "this" {
  for_each = var.stages

  rest_api_id          = aws_api_gateway_rest_api.this.id
  deployment_id        = aws_api_gateway_deployment.this.id
  stage_name           = each.key
  description          = each.value.description
  variables            = each.value.stage_variables
  xray_tracing_enabled = coalesce(each.value.xray_tracing_enabled, false)
  tags                 = merge(var.tags, each.value.tags)

  dynamic "access_log_settings" {
    for_each = local.stage_logging[each.key].enabled ? [local.stage_logging[each.key]] : []

    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[each.key].arn
      format          = access_log_settings.value.format
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.api_gateway,
  ]
}

# Stage-wide default settings applied to all methods ("*/*").
resource "aws_api_gateway_method_settings" "defaults" {
  for_each = {
    for name, stage in var.stages : name => stage
    if(
      coalesce(try(stage.throttling.enabled, null), false) ||
      coalesce(stage.detailed_metrics_enabled, false) ||
      stage.logging_level != null ||
      coalesce(stage.data_trace_enabled, false)
    )
  }

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this[each.key].stage_name
  method_path = "*/*"

  settings {
    # -1 means inherit from the account-level default (effectively no stage-imposed limit).
    throttling_burst_limit = coalesce(try(each.value.throttling.enabled, null), false) ? coalesce(try(each.value.throttling.burst_limit, null), 200) : -1
    throttling_rate_limit  = coalesce(try(each.value.throttling.enabled, null), false) ? coalesce(try(each.value.throttling.rate_limit, null), 100) : -1
    metrics_enabled        = coalesce(each.value.detailed_metrics_enabled, false)
    logging_level          = coalesce(each.value.logging_level, "OFF")
    data_trace_enabled     = coalesce(each.value.data_trace_enabled, false)
  }
}

# Per-route method settings overrides within a stage.
# Key format: "{stage_name}/{route_key}" e.g. "dev/health-check"
resource "aws_api_gateway_method_settings" "routes" {
  for_each = merge([
    for stage_name, stage in var.stages : {
      for route_key, settings in stage.route_settings :
      "${stage_name}/${route_key}" => merge(settings, {
        stage_name  = stage_name
        method_path = local.route_method_paths[route_key]
      })
    }
  ]...)

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this[each.value.stage_name].stage_name
  method_path = each.value.method_path

  settings {
    throttling_burst_limit = coalesce(each.value.throttling_burst_limit, -1)
    throttling_rate_limit  = coalesce(each.value.throttling_rate_limit, -1)
    metrics_enabled        = coalesce(each.value.detailed_metrics_enabled, false)
    logging_level          = coalesce(each.value.logging_level, "OFF")
    data_trace_enabled     = coalesce(each.value.data_trace_enabled, false)
  }
}
