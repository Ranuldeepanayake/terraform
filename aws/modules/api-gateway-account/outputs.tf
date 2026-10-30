output "cloudwatch_role_arn" {
  description = "ARN of the IAM role configured as the API Gateway account-level CloudWatch Logs role"
  value       = aws_iam_role.this.arn
}

output "cloudwatch_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}
