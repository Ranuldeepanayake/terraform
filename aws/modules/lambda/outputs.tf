output "lambda_function_name" {
  description = "Name of the Lambda function."
  value = aws_lambda_function.this.function_name
}

output "lambda_version" {
  description = "Version of the Lambda function."
  value = aws_lambda_function.this.version
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value = aws_lambda_function.this.arn
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function."
  value = aws_lambda_function.this.invoke_arn
}

output "lambda_create_role" {
  description = "Whether a new IAM role was created for the Lambda function."
  value       = var.create_role
}

# Show the role name if one was newly created or null if an existing one was used.
output "lambda_role_name" {
  description = "Name of the Lambda execution IAM role"
  value       = var.create_role ? aws_iam_role.lambda_role[0].name : null
}

# Show the created role ARN if a new role was created, or the existing role ARN if an existing role was used.
output "lambda_role_arn" {
  description = "Show the created role ARN if a new role was created, or the existing role ARN if an existing role was used."
  value = var.create_role ? aws_iam_role.lambda_role[0].arn : var.lambda_role_arn
}

# Show the policy ARN if a new policy was created.
output "lambda_created_custom_policy_arns" {
  description = "ARNs of custom IAM policies created by the module"
  value = aws_iam_policy.lambda_custom[*].arn
}

# Show the policy ARNs if existing policies were used.
output "lambda_existing_custom_policy_arns" {
  description = "ARNs of existing IAM policies attached by the module"
  value = var.create_role ? var.custom_policy_arns : []
}

# Show all custom policies, both newly created and existing.
output "lambda_all_custom_policy_arns" {
  description = "All custom IAM policy ARNs, both created and existing"
  value = concat(
    aws_iam_policy.lambda_custom[*].arn,
    var.create_role ? var.custom_policy_arns : []
  )
}

output "lambda_function_url" {
  description = "URL of the Lambda function."
  value = var.create_function_url ? aws_lambda_function_url.this[0].function_url : null
}

output "lambda_create_security_group" {
  description = "Whether a new security group was created for the Lambda function."
  value       = local.create_lambda_security_group
}

# Show the security group name if one was newly created or null if an existing one was used.
output "lambda_created_security_group_name" {
  description = "Name of the Lambda security group"
  value       = var.create_security_group ? aws_security_group.lambda[0].name : null
}

output "lambda_created_security_group_id" {
  description = "ID of the security group created by this module, or null if none was created."
  value       = local.create_lambda_security_group ? aws_security_group.lambda[0].id : null
}

output "lambda_created_security_group_arn" {
  description = "ARN of the security group created by this module, or null if none was created."
  value       = local.create_lambda_security_group ? aws_security_group.lambda[0].arn : null
}

# Show all associated security group IDs, including any existing ones provided by the user and any newly created one.
output "lambda_all_security_group_ids" {
  description = "Security groups associated with the Lambda function."
  value       = local.lambda_security_group_ids
}

# Last modified time of the Lambda function.
output "lambda_last_modified" {
  description = "Last modified time of the Lambda function."
  value = aws_lambda_function.this.last_modified
}