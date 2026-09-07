output "arn" {
  description = "ARN of the Secrets Manager secret."
  value       = aws_secretsmanager_secret.this.arn
}

output "name" {
  description = "Name of the Secrets Manager secret."
  value       = aws_secretsmanager_secret.this.name
}

output "id" {
  description = "ID of the Secrets Manager secret."
  value       = aws_secretsmanager_secret.this.id
}