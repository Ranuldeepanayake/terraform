data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Create IAM role for the Lambda function if specified.
resource "aws_iam_role" "lambda_role" {
  count = var.create_role ? 1 : 0

  name = "CustomRoleLambda-${var.lambda_role_name}"

  # Configures this role to be assumed only by a specific Lambda function from a specific source AWS account.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "lambda.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

# Attach a basic policy to the above created role if create_role is true.
resource "aws_iam_role_policy_attachment" "basic" {
  count      = var.create_role ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach the VPC access policy to the above created role if create_role is true and vpc_subnet_ids is not empty (which indicates the need to access VPC resources).
resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = (var.create_role && length(var.vpc_subnet_ids) > 0) ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# If an inline custom policy is passed in, create the policy object. 
resource "aws_iam_policy" "lambda_custom" {
  count = var.create_role && var.custom_policy != null ? 1 : 0

  name        = "CustomPolicyLambda-${var.function_name}"
  description = "Custom policy for the Lambda function ${var.function_name}"

  policy = var.custom_policy
}

# If an inline custom policy is passed in, attach it to the role the module creates.
resource "aws_iam_role_policy_attachment" "custom" {
  count = var.create_role && var.custom_policy != null ? 1 : 0

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.lambda_custom[0].arn
}

# If a list of existing custom policies are passed in, attach them to the role the module creates.
resource "aws_iam_role_policy_attachment" "custom_existing" {
  for_each = var.create_role ? toset(var.custom_policy_arns) : toset([])

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = each.value
}

# Inline ZIP file creation if use_inline_code is true and inline_code is provided.
data "archive_file" "inline_zip" {
  count = local.using_inline ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/lambda_inline.zip"

  source {
    content  = var.inline_code
    filename = "index.js"
  }
}