# Logging with Cloudwatch.
resource "aws_cloudwatch_log_group" "api_gateway" {
  count = var.logging.enabled ? 1 : 0

  name              = var.logging.log_group_name != "" ? var.logging.log_group_name : "/aws/apigateway/${var.api_gateway_name}"
  retention_in_days = var.logging.retention_in_days
}

# Stage settings for throttling, access logging and detailed metrics.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  # Access log settings for the stage. Applicable to all routes in the stage. Only created if logging is enabled.
  dynamic "access_log_settings" {
    for_each = var.logging.enabled ? [1] : []

    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn

      format = jsonencode({
        requestId        = "$context.requestId"
        sourceIp         = "$context.identity.sourceIp"
        requestTime      = "$context.requestTime"
        httpMethod       = "$context.httpMethod"
        routeKey         = "$context.routeKey"
        status           = "$context.status"
        protocol         = "$context.protocol"
        responseLength   = "$context.responseLength"
        integrationError = "$context.integrationErrorMessage"
      })
    }
  }

  # Throttling settings applicable for all routes in the stage. Only created if throttling is enabled.
  dynamic "default_route_settings" {
    for_each = (var.throttling.enabled || var.detailed_metrics_enabled) ? [1] : []

    content {
      detailed_metrics_enabled = var.detailed_metrics_enabled
      throttling_rate_limit    = var.throttling.rate_limit
      throttling_burst_limit   = var.throttling.burst_limit
    }
  }
}