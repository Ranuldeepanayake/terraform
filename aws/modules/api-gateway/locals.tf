locals {
  stage_logging = {
    for name, stage in var.stages : name => {
      enabled = coalesce(stage.logging.enabled, var.logging.enabled)
      log_group_name = coalesce(
        stage.logging.log_group_name,
        name == "$default" && var.logging.log_group_name != "" ? var.logging.log_group_name : null,
        name == "$default" ? "/aws/apigateway/${var.api_gateway_name}" : "/aws/apigateway/${var.api_gateway_name}/${name}"
      )
      retention_in_days = coalesce(stage.logging.retention_in_days, var.logging.retention_in_days)
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

  custom_domain_mappings = var.custom_domain == null ? {} : (
    length(local.custom_domain_mappings_by_stage) > 0 ? local.custom_domain_mappings_by_stage : {
      legacy = {
        stage_name  = var.custom_domain_stage
        mapping_key = null
      }
    }
  )
}
