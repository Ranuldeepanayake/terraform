output "api_gateway_id" {
  description = "API Gateway API ID"
  value       = module.api_gateway.api_gateway_id
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint"
  value       = module.api_gateway.api_gateway_endpoint
}

output "api_gateway_routes" {
  description = "API Gateway routes"
  value       = module.api_gateway.api_gateway_routes
}