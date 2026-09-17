output "arn" {
  description = "ARN of the IAM role."
  value       = aws_iam_role.this.arn
}

output "name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.this.name
}

output "id" {
  description = "Name/ID of the IAM role."
  value       = aws_iam_role.this.id
}

output "path" {
  description = "Path of the IAM role."
  value       = aws_iam_role.this.path
}

output "role_id" {
  description = "Unique ID of the IAM role."
  value       = aws_iam_role.this.unique_id
}

output "inline_policy_names" {
  description = "Names of the inline policies created for the IAM role."
  value       = keys(aws_iam_role_policy.this)
}

output "external_policy_arns" {
  description = "ARNs of the IAM policies attached to the role."
  value       = var.external_policy_arns
}