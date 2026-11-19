output "api_gateway_id" {
  description = "REST API ID"
  value       = module.api_gateway.api_gateway_id
}

output "api_gateway_execution_arn" {
  description = "REST API execution ARN"
  value       = module.api_gateway.api_gateway_execution_arn
}

output "api_gateway_stage_urls" {
  description = "Stage invoke URLs"
  value       = module.api_gateway.api_gateway_stage_urls
}

output "api_gateway_custom_domain_urls" {
  description = "Custom-domain invoke URLs by stage"
  value       = module.api_gateway.api_gateway_custom_domain_urls
}

output "api_gateway_routes" {
  description = "Configured routes"
  value       = module.api_gateway.api_gateway_routes
}

output "api_gateway_api_key_ids" {
  description = "API key IDs by usage plan"
  value       = module.api_gateway.api_gateway_api_key_ids
}

output "api_gateway_usage_plan_ids" {
  description = "Usage plan IDs by plan name"
  value       = module.api_gateway.api_gateway_usage_plan_ids
}
