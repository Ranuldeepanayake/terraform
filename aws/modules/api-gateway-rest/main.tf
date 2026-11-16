data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_gateway_name
  description = var.description

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = var.tags
}

# Path resources are split into four depth levels to avoid Terraform's self-referential resource
# constraint. Each level references only the previous level. Paths beyond 4 segments are rejected
# by validation in var.routes.
resource "aws_api_gateway_resource" "l1" {
  for_each    = local.path_nodes_l1
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.segment
}

resource "aws_api_gateway_resource" "l2" {
  for_each    = local.path_nodes_l2
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.l1[each.value.parent_path].id
  path_part   = each.value.segment
}

resource "aws_api_gateway_resource" "l3" {
  for_each    = local.path_nodes_l3
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.l2[each.value.parent_path].id
  path_part   = each.value.segment
}

resource "aws_api_gateway_resource" "l4" {
  for_each    = local.path_nodes_l4
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.l3[each.value.parent_path].id
  path_part   = each.value.segment
}

resource "aws_api_gateway_method" "this" {
  for_each = var.routes

  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = local.all_resource_ids[each.value.path]
  http_method      = upper(each.value.method)
  authorization    = each.value.authorization
  api_key_required = coalesce(each.value.api_key_required, false)
}

resource "aws_api_gateway_integration" "lambda" {
  for_each = var.routes

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = local.all_resource_ids[each.value.path]
  http_method             = aws_api_gateway_method.this[each.key].http_method
  integration_http_method = var.integration_method
  type                    = var.integration_type
  # REST API requires the ARN-in-URI form for Lambda integrations; HTTP API uses the Lambda ARN directly.
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:lambda:path/2015-03-31/functions/${var.lambda_functions[each.value.lambda].arn}/invocations"
  timeout_milliseconds    = var.integration_timeout_milliseconds
}

# Wildcard stage and method in source_arn covers all current and future stages without needing per-stage permissions.
resource "aws_lambda_permission" "api_gateway" {
  for_each = var.routes

  statement_id  = "AllowApiGateway-${replace(each.key, "-", "")}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_functions[each.value.lambda].arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
