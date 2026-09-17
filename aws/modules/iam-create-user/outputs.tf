output "user_name" {
  description = "The name of the IAM user."
  value       = aws_iam_user.this.name
}

output "user_arn" {
  description = "The ARN of the IAM user."
  value       = aws_iam_user.this.arn
}

output "access_key_id" {
  description = "The access key ID of the IAM user, if an access key was created."
  value       = var.create_access_key ? aws_iam_access_key.this[0].id : null
  sensitive   = true
}

output "secret_access_key" {
  description = "The secret access key of the IAM user, if an access key was created."
  value       = var.create_access_key ? aws_iam_access_key.this[0].secret : null
  sensitive   = true
}

output "inline_policy_names" {
  description = "Names of the inline policies attached to the IAM user."
  value       = keys(aws_iam_user_policy.this)
}

output "external_policy_arns" {
  description = "ARNs of the IAM policies attached to the user."
  value       = var.external_policy_arns
}