variable "minimum_password_length" {
  description = "Minimum number of characters required for IAM user passwords."
  type        = number
  default     = 12
}

variable "require_uppercase_characters" {
  description = "Require at least one uppercase character."
  type        = bool
  default     = true
}

variable "require_lowercase_characters" {
  description = "Require at least one lowercase character."
  type        = bool
  default     = true
}

variable "require_numbers" {
  description = "Require at least one number."
  type        = bool
  default     = true
}

variable "require_symbols" {
  description = "Require at least one symbol."
  type        = bool
  default     = true
}

variable "allow_users_to_change_password" {
  description = "Allow IAM users to change their own passwords."
  type        = bool
  default     = true
}

variable "hard_expiry" {
  description = "Prevent administrators from resetting expired passwords."
  type        = bool
  default     = false
}

variable "max_password_age" {
  description = "Maximum password age in days. Set to 0 for no expiration."
  type        = number
  default     = 0
}

variable "password_reuse_prevention" {
  description = "Number of previous passwords that users cannot reuse."
  type        = number
  default     = 5
}