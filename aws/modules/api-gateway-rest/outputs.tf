output "api_gateway_id" {
  description = "REST API ID"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_gateway_execution_arn" {
  description = "REST API execution ARN"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "api_gateway_stage_urls" {
  description = "Invoke URLs for each configured stage. Stage name is always embedded in the path."
  value = {
    for name in keys(aws_api_gateway_stage.this) :
    name => "https://${aws_api_gateway_rest_api.this.id}.execute-api.${data.aws_region.current.region}.amazonaws.com/${name}"
  }
}

output "api_gateway_custom_domain_urls" {
  description = "Custom-domain invoke URLs keyed by stage name."
  value = {
    for name, mapping in local.custom_domain_mappings_by_stage :
    mapping.stage_name => mapping.mapping_key == "" ? "https://${var.custom_domain}" : "https://${var.custom_domain}/${mapping.mapping_key}"
  }
}

output "api_gateway_routes" {
  description = "Configured API Gateway routes"
  value = {
    for key, route in var.routes :
    key => {
      method           = upper(route.method)
      path             = route.path
      lambda           = route.lambda
      authorization    = route.authorization
      api_key_required = coalesce(route.api_key_required, false)
    }
  }
}

output "api_gateway_api_key_ids" {
  description = "API key IDs keyed by usage plan name. Present only when api_key_required routes exist."
  value = {
    for key, api_key in aws_api_gateway_api_key.this :
    key => api_key.id
  }
}

output "api_gateway_api_key_values" {
  description = "API key values keyed by usage plan name. Sensitive."
  sensitive   = true
  value = {
    for key, api_key in aws_api_gateway_api_key.this :
    key => api_key.value
  }
}

output "api_gateway_usage_plan_ids" {
  description = "Usage plan IDs keyed by plan name."
  value = {
    for key, plan in aws_api_gateway_usage_plan.this :
    key => plan.id
  }
}
