output "iam_create_role_arn" {
  description = "ARN of the IAM role created by the iam_create_role module."
  value       = module.iam_create_role.arn
}

output "iam_create_role_name" {
  description = "Name of the IAM role created by the iam_create_role module."
  value       = module.iam_create_role.name
}

output "iam_create_role_id" {
  description = "ID of the IAM role created by the iam_create_role module."
  value       = module.iam_create_role.id
}

output "iam_create_role_path" {
  description = "Path of the IAM role created by the iam_create_role module."
  value       = module.iam_create_role.path
}

output "iam_create_role_role_id" {
  description = "Unique ID of the IAM role created by the iam_create_role module."
  value       = module.iam_create_role.role_id
}