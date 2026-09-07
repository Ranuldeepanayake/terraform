output "api_gateway_id" {
  description = "API Gateway API ID"
  value       = aws_apigatewayv2_api.this.id
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint"
  value       = aws_apigatewayv2_api.this.api_endpoint
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