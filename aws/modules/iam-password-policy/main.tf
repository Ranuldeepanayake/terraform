# Create a password policy.
resource "aws_iam_account_password_policy" "this" {
  minimum_password_length      = var.minimum_password_length
  require_uppercase_characters = var.require_uppercase_characters
  require_lowercase_characters = var.require_lowercase_characters
  require_numbers              = var.require_numbers
  require_symbols              = var.require_symbols

  allow_users_to_change_password = var.allow_users_to_change_password

  hard_expiry               = var.hard_expiry
  max_password_age          = var.max_password_age
  password_reuse_prevention = var.password_reuse_prevention
}