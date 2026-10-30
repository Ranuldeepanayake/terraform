output "cloudwatch_role_arn" {
  description = "ARN of the API Gateway account-level CloudWatch Logs role"
  value       = module.api_gateway_account.cloudwatch_role_arn
}

output "cloudwatch_role_name" {
  description = "Name of the IAM role"
  value       = module.api_gateway_account.cloudwatch_role_name
}
