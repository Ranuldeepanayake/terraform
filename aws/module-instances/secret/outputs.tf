output "arn" {
  description = "ARN of the Secrets Manager secret."
  value       = module.secret.arn
}

output "name" {
  description = "Name of the Secrets Manager secret."
  value       = module.secret.name
}

output "id" {
  description = "ID of the Secrets Manager secret."
  value       = module.secret.id
}