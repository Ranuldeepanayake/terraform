# Lookup the VPC ID based on subnet IDs provided. This is used to create a security group in the same VPC as the Lambda function.
data "aws_subnet" "lambda" {
  count = local.create_lambda_security_group ? 1 : 0

  id = var.vpc_subnet_ids[0]
}

# Create the Lambda function with the specified configuration.
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description

  role = var.create_role ? aws_iam_role.lambda_role[0].arn : var.lambda_role_arn

  handler          = var.handler
  runtime          = var.runtime
  memory_size      = var.memory_size
  timeout          = var.timeout
  filename         = local.using_inline ? data.archive_file.inline_zip[0].output_path : var.source_path
  source_code_hash = local.using_inline ? data.archive_file.inline_zip[0].output_base64sha256 : filebase64sha256(var.source_path)

  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  dynamic "vpc_config" {
    for_each = length(var.vpc_subnet_ids) > 0 ? [1] : []

    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = local.lambda_security_group_ids
    }
  }

  environment {
    variables = var.environment_variables
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.basic,
    aws_iam_role_policy_attachment.vpc_access,
    aws_iam_role_policy_attachment.custom,
    aws_iam_role_policy_attachment.custom_existing
  ]

  # Ignore changes to the filename, source_code_hash and environment variable attributes to prevent unnecessary Lambda function updates when infrastructure is updated.
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      environment
    ]
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "LambdaFunction"
    }
  )
}

# Asynchronous invocation configuration. The function caller does not wait for a result when enabled.
resource "aws_lambda_function_event_invoke_config" "this" {
  count = var.create_function_event_invoke_config ? 1 : 0

  function_name                = aws_lambda_function.this.function_name
  maximum_event_age_in_seconds = var.maximum_event_age_in_seconds
  maximum_retry_attempts       = var.maximum_retry_attempts
}

# Create an optional Lambda function URL if specified along with CORS configuration.
resource "aws_lambda_function_url" "this" {
  count = var.create_function_url ? 1 : 0

  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.authorization_type

  dynamic "cors" {
    for_each = var.cors != null ? [1] : []
    content {
      allow_origins = var.cors.allow_origins
      allow_methods = var.cors.allow_methods
      allow_headers = var.cors.allow_headers
    }
  }
}

# Allow public access to the Lambda function URL if authorization type is NONE.
resource "aws_lambda_permission" "url_public" {
  count = var.create_function_url && var.authorization_type == "NONE" ? 1 : 0

  statement_id           = "AllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# Create a CloudWatch log group for the Lambda function with the specified retention period.
resource "aws_cloudwatch_log_group" "lambda" {
  name_prefix       = "/aws/lambda/${var.function_name}-"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      ResourceType = "CloudwatchLogGroup"
    }
  )
}