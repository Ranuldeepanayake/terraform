locals {
  stage_logging = {
    for name, stage in var.stages : name => {
      enabled           = coalesce(stage.logging.enabled, true)
      log_group_name = coalesce(
        stage.logging.log_group_name,
        name == "$default" ? "/aws/apigateway/${var.api_gateway_name}" : "/aws/apigateway/${var.api_gateway_name}/${name}"
      )
      retention_in_days = coalesce(stage.logging.retention_in_days, 30)
      format = coalesce(stage.logging.format, jsonencode({
        requestId        = "$context.requestId"
        sourceIp         = "$context.identity.sourceIp"
        requestTime      = "$context.requestTime"
        httpMethod       = "$context.httpMethod"
        routeKey         = "$context.routeKey"
        status           = "$context.status"
        protocol         = "$context.protocol"
        responseLength   = "$context.responseLength"
        integrationError = "$context.integrationErrorMessage"
      }))
    }
  }

  custom_domain_mappings_by_stage = {
    for name, stage in var.stages : name => {
      stage_name  = name
      mapping_key = stage.custom_domain_mapping_key
    } if var.custom_domain != null && stage.custom_domain_mapping_key != null
  }
}
