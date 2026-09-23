variable "username" {
  description = "The name of the IAM user to create."
  type        = string
}

variable "path" {
  description = "The IAM path under which the user is created. Use paths to organize IAM users into logical groups, such as /developers/ or /service-accounts/."
  type        = string
  default     = "/"
}

variable "create_console_login" {
  description = "Whether to create an IAM login profile that allows the user to sign in to the AWS Management Console with a username and password."
  type        = bool
  default     = false
}

variable "password_length" {
  description = "Length of the automatically generated IAM console password."
  type        = number
  default     = 20

  validation {
    condition     = var.password_length >= 1 && var.password_length <= 128
    error_message = "Password length must be between 1 and 128 characters."
  }
}

variable "password_reset_required" {
  description = "Whether the user must change the automatically generated console password when signing in for the first time. This setting applies only when create_console_login is enabled."
  type        = bool
  default     = true
}

variable "create_access_key" {
  description = "Whether to create an IAM access key for programmatic access to AWS APIs and services. Access keys should only be created when required."
  type        = bool
  default     = false
}

variable "groups" {
  description = "A list of IAM group names to which the user will be added. Groups can be used to assign permissions to the user through group policies."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = <<-EOT
    Map of inline IAM policies to attach directly to the user.

    Example:

    inline_policies = {
      "S3Access"      = "$${path.root}/policies/s3-access.json"
      "SecretsAccess" = "$${path.root}/policies/secrets-access.json"
    }

    An empty map means that no inline policies are created.
  EOT

  type    = map(string)
  default = {}
}

variable "external_policy_arns" {
  description = <<-EOT
    List of ARNs of existing IAM policies to attach to the user.

    Example:

    policy_arns = [
      "arn:aws:iam::aws:policy/IAMFullAccess",
      "arn:aws:iam::104322896078:policy/CustomPolicy"
    ]

    An empty list means that no external policies are attached.
  EOT

  type    = list(string)
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the IAM user for identification, organization, cost allocation, and resource management."
  type        = map(string)
  default     = {}
}