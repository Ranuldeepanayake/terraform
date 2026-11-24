# Return repository identity and endpoint values regardless of repository type.
output "repository_name" {
  description = "Name of the ECR repository."
  value       = var.repository_type == "private" ? aws_ecr_repository.this[0].name : aws_ecrpublic_repository.this[0].repository_name
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = var.repository_type == "private" ? aws_ecr_repository.this[0].arn : aws_ecrpublic_repository.this[0].arn
}

output "repository_url" {
  description = "Docker registry URI of the ECR repository."
  value       = var.repository_type == "private" ? aws_ecr_repository.this[0].repository_url : aws_ecrpublic_repository.this[0].repository_uri
}

output "registry_id" {
  description = "Registry account ID associated with the repository."
  value       = var.repository_type == "private" ? aws_ecr_repository.this[0].registry_id : aws_ecrpublic_repository.this[0].registry_id
}

output "repository_type" {
  description = "Whether this is a private or public repository."
  value       = var.repository_type
}

output "tags" {
  description = "Tags applied to the repository."
  value       = var.repository_type == "private" ? aws_ecr_repository.this[0].tags_all : aws_ecrpublic_repository.this[0].tags_all
}
