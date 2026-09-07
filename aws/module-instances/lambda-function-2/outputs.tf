output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.lambda_function_name
}

output "lambda_version" {
  description = "Published Lambda version"
  value       = module.lambda.lambda_version
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.lambda_function_arn
}

output "lambda_invoke_arn" {
  description = "Lambda invocation ARN"
  value       = module.lambda.lambda_invoke_arn
}

output "lambda_create_role" {
  description = "Whether a new IAM role was created for the Lambda function."
  value       = module.lambda.lambda_create_role
}

# Show the role name if one was newly created or null if an existing one was used.
output "role_name" {
  description = "Name of the Lambda execution IAM role"
  value       = module.lambda.lambda_role_name
}

# Show the created role ARN if a new role was created, or the existing role ARN if an existing role was used.
output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = module.lambda.lambda_role_arn
}

output "lambda_function_url" {
  description = "Public Lambda Function URL"
  value       = module.lambda.lambda_function_url
}

output "lambda_create_security_group" {
  description = "Whether a new security group was created for the Lambda function."
  value       = module.lambda.lambda_create_security_group
}

# Show the security group name if one was newly created or null if an existing one was used.
output "security_group_name" {
  description = "Name of the Lambda security group"
  value       = module.lambda.lambda_created_security_group_name
}

output "lambda_created_security_group_id" {
  description = "Security group created by the Lambda module"
  value       = module.lambda.lambda_created_security_group_id
}

output "lambda_created_security_group_arn" {
  description = "ARN of the security group created by the Lambda module"
  value       = module.lambda.lambda_created_security_group_arn
}

# Show all associated security group IDs, including any existing ones provided by the user and any newly created one.
output "lambda_all_security_group_ids" {
  description = "Security groups associated with Lambda"
  value       = module.lambda.lambda_all_security_group_ids
}

output "lambda_last_modified" {
  value = module.lambda.lambda_last_modified
}