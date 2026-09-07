# Main API Gateway resource. This is the entry point for the API Gateway and is used to create the API Gateway itself.
resource "aws_apigatewayv2_api" "this" {
  name            = var.api_gateway_name
  protocol_type   = var.protocol_type
  ip_address_type = var.ip_address_type

  cors_configuration {
    allow_headers = var.cors_configuration.allow_headers
    allow_methods = var.cors_configuration.allow_methods
    allow_origins = var.cors_configuration.allow_origins
  }
}

# Lambda integrations. Uses the same loop key as the routes to ensure that each integration has the matching route.
resource "aws_apigatewayv2_integration" "lambda" {
  for_each = var.routes

  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = var.integration_type
  integration_uri        = var.lambda_functions[each.value.lambda].arn
  integration_method     = var.integration_method
  payload_format_version = var.payload_format_version
  timeout_milliseconds   = var.integration_timeout_milliseconds
}

# API routes. Uses the same loop key as the integrations to ensure that each route has the matching integration.
resource "aws_apigatewayv2_route" "this" {
  for_each = var.routes

  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "${upper(each.value.method)} ${each.value.path}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
  authorization_type = each.value.authorization
}

# Default route if a route is marked as default.
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target = "integrations/${aws_apigatewayv2_integration.lambda[
    one([for key, route in var.routes : key if route.default])
  ].id}"
  authorization_type = one([for route in var.routes : route.authorization if route.default])
}

# Allow API Gateway to invoke Lambda.
resource "aws_lambda_permission" "api_gateway" {
  for_each = var.routes

  statement_id  = "AllowApiGateway-${replace(each.key, "-", "")}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_functions[each.value.lambda].arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}