output "iam_create_policy_id" {
  description = "ARN of the IAM policy created by the iam_create_policy module."
  value       = module.iam_create_policy.id
}

output "iam_create_policy_arn" {
  description = "ARN of the IAM policy created by the iam_create_policy module."
  value       = module.iam_create_policy.arn
}

output "iam_create_policy_name" {
  description = "Name of the IAM policy created by the iam_create_policy module."
  value       = module.iam_create_policy.name
}

output "iam_create_policy_path" {
  description = "Path of the IAM policy created by the iam_create_policy module."
  value       = module.iam_create_policy.path
}

output "iam_create_policy_policy_id" {
  description = "Unique ID of the IAM policy created by the iam_create_policy module."
  value       = module.iam_create_policy.policy_id
}