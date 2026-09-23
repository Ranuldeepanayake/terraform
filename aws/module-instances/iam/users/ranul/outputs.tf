output "user_name" {
  description = "The name of the IAM user created by the iam_create_user module."
  value       = module.iam_create_user.user_name
}

output "user_arn" {
  description = "The ARN of the IAM user created by the iam_create_user module."
  value       = module.iam_create_user.user_arn
}

#output "iam_user_console_password" {
#  description = "The auto generated password by AWS IAM"
#  value       = module.iam_create_user.console_password
#  sensitive   = true
#}

output "access_key_id" {
  description = "The access key ID of the IAM user created by the iam_create_user module, if an access key was created."
  value       = module.iam_create_user.access_key_id
  sensitive   = true
}

output "secret_access_key" {
  description = "The secret access key of the IAM user created by the iam_create_user module, if an access key was created."
  value       = module.iam_create_user.secret_access_key
  sensitive   = true
}

output "iam_create_user_inline_policy_names" {
  description = "Names of the inline policies attached to the IAM user."
  value       = module.iam_create_user.inline_policy_names
}

output "iam_create_user_external_policy_arns" {
  description = "ARNs of the external IAM policies attached to the IAM user."
  value       = module.iam_create_user.external_policy_arns
}