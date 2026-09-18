output "name" {
  description = "Name of the IAM group."
  value       = aws_iam_group.this.name
}

output "arn" {
  description = "ARN of the IAM group."
  value       = aws_iam_group.this.arn
}

output "id" {
  description = "Name/ID of the IAM group."
  value       = aws_iam_group.this.id
}

output "path" {
  description = "Path of the IAM group."
  value       = aws_iam_group.this.path
}

output "inline_policy_names" {
  description = "Names of the inline policies created for the IAM group."
  value       = keys(aws_iam_group_policy.this)
}

output "external_policy_arns" {
  description = "ARNs of the external managed policies attached to the IAM group."
  value       = var.external_policy_arns
}
