output "api_gateway_id" {
  description = "API Gateway API ID"
  value       = module.api_gateway.api_gateway_id
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint"
  value       = module.api_gateway.api_gateway_endpoint
}

output "api_gateway_stage_urls" {
  description = "API Gateway stage URLs"
  value       = module.api_gateway.api_gateway_stage_urls
}

output "api_gateway_custom_domain_urls" {
  description = "API Gateway custom-domain URLs by stage"
  value       = module.api_gateway.api_gateway_custom_domain_urls
}

output "api_gateway_routes" {
  description = "API Gateway routes"
  value       = module.api_gateway.api_gateway_routes
}