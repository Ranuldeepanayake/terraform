output "iam_create_group_name" {
  description = "Name of the IAM group created by the iam_create_group module."
  value       = module.iam_create_group.name
}

output "iam_create_group_arn" {
  description = "ARN of the IAM group created by the iam_create_group module."
  value       = module.iam_create_group.arn
}

output "iam_create_group_id" {
  description = "ID of the IAM group created by the iam_create_group module."
  value       = module.iam_create_group.id
}

output "iam_create_group_path" {
  description = "Path of the IAM group created by the iam_create_group module."
  value       = module.iam_create_group.path
}

output "iam_create_group_inline_policy_names" {
  description = "Names of the inline policies created for the IAM group."
  value       = module.iam_create_group.inline_policy_names
}

output "iam_create_group_external_policy_arns" {
  description = "ARNs of the external managed policies attached to the IAM group."
  value       = module.iam_create_group.external_policy_arns
}