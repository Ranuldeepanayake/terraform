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