output "api_gateway_id" {
  description = "API Gateway API ID"
  value       = aws_apigatewayv2_api.this.id
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_gateway_stage_urls" {
  description = "Invoke URLs for each configured API Gateway stage."
  value = {
    for name, _ in aws_apigatewayv2_stage.this :
    name => name == "$default" ? aws_apigatewayv2_api.this.api_endpoint : "${aws_apigatewayv2_api.this.api_endpoint}/${name}"
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
      method        = upper(route.method)
      path          = route.path
      lambda        = route.lambda
      authorization = route.authorization
    }
  }
}