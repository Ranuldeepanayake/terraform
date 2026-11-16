# MOCK integration handles preflight only. Lambda must include CORS headers (Access-Control-Allow-Origin etc.)
# in actual responses; API Gateway cannot inject them into AWS_PROXY passthrough responses.
locals {
  cors_resources = var.cors_configuration != null ? local.all_path_nodes : toset([])
}

resource "aws_api_gateway_method" "options" {
  for_each = local.cors_resources

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = local.all_resource_ids[each.key]
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each = local.cors_resources

  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = local.all_resource_ids[each.key]
  http_method          = aws_api_gateway_method.options[each.key].http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.all_resource_ids[each.key]
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.all_resource_ids[each.key]
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options[each.key].status_code

  # try() guards prevent null-access errors: for_each being empty does not stop Terraform from evaluating
  # these expressions during type checking when cors_configuration is null.
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${join(",", try(var.cors_configuration.allow_headers, []))}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${join(",", concat(try(var.cors_configuration.allow_methods, []), ["OPTIONS"]))}'"
    # Access-Control-Allow-Origin accepts only a single value or *; provide one origin or * in allow_origins.
    "method.response.header.Access-Control-Allow-Origin"  = "'${join(",", try(var.cors_configuration.allow_origins, []))}'"
  }

  depends_on = [aws_api_gateway_integration.options]
}
