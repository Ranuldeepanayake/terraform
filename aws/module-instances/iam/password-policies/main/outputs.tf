output "iam_password_policy" {
  description = "Configured IAM account password policy."

  value = {
    id                             = module.iam_password_policy.password_policy_id
    minimum_password_length        = module.iam_password_policy.minimum_password_length
    require_uppercase_characters   = module.iam_password_policy.require_uppercase_characters
    require_lowercase_characters   = module.iam_password_policy.require_lowercase_characters
    require_numbers                = module.iam_password_policy.require_numbers
    require_symbols                = module.iam_password_policy.require_symbols
    allow_users_to_change_password = module.iam_password_policy.allow_users_to_change_password
    hard_expiry                    = module.iam_password_policy.hard_expiry
    max_password_age               = module.iam_password_policy.max_password_age
    password_reuse_prevention      = module.iam_password_policy.password_reuse_prevention
  }
}