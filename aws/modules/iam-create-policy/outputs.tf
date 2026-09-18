output "id" {
  description = "ARN of the IAM policy."
  value       = aws_iam_policy.this.id
}

output "arn" {
  description = "ARN of the IAM policy."
  value       = aws_iam_policy.this.arn
}

output "name" {
  description = "Name of the IAM policy."
  value       = aws_iam_policy.this.name
}

output "path" {
  description = "Path of the IAM policy."
  value       = aws_iam_policy.this.path
}

output "policy_id" {
  description = "Unique ID of the IAM policy."
  value       = aws_iam_policy.this.policy_id
}