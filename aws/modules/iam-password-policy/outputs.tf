output "minimum_password_length" {
  description = "Minimum number of characters required for IAM user passwords."
  value       = aws_iam_account_password_policy.this.minimum_password_length
}

output "require_uppercase_characters" {
  description = "Whether IAM passwords must contain at least one uppercase character."
  value       = aws_iam_account_password_policy.this.require_uppercase_characters
}

output "require_lowercase_characters" {
  description = "Whether IAM passwords must contain at least one lowercase character."
  value       = aws_iam_account_password_policy.this.require_lowercase_characters
}

output "require_numbers" {
  description = "Whether IAM passwords must contain at least one number."
  value       = aws_iam_account_password_policy.this.require_numbers
}

output "require_symbols" {
  description = "Whether IAM passwords must contain at least one symbol."
  value       = aws_iam_account_password_policy.this.require_symbols
}

output "allow_users_to_change_password" {
  description = "Whether IAM users are allowed to change their own passwords."
  value       = aws_iam_account_password_policy.this.allow_users_to_change_password
}

output "hard_expiry" {
  description = "Whether administrators are prevented from resetting expired passwords."
  value       = aws_iam_account_password_policy.this.hard_expiry
}

output "max_password_age" {
  description = "Maximum number of days an IAM user password can remain valid. A value of 0 means no expiration."
  value       = aws_iam_account_password_policy.this.max_password_age
}

output "password_reuse_prevention" {
  description = "Number of previous passwords that IAM users are prevented from reusing."
  value       = aws_iam_account_password_policy.this.password_reuse_prevention
}

output "password_policy_id" {
  description = "ID of the IAM account password policy resource."
  value       = aws_iam_account_password_policy.this.id
}