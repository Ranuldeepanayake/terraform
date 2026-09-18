variable "name" {
  description = "Name of the IAM group."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The IAM group name must not be empty."
  }
}

variable "path" {
  description = "IAM path under which the group is created. Use paths to organize IAM groups into logical groups."
  type        = string
  default     = "/"
}

variable "inline_policies" {
  description = <<-EOT
    Map of inline IAM policy names to JSON policy file paths.

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
    Set of ARNs of external managed IAM policies to attach to the group.

    Example:

    policy_arns = [
      "arn:aws:iam::aws:policy/IAMFullAccess",
      "arn:aws:iam::123456789012:policy/CustomPolicy"
    ]

    An empty set means that no external policies are attached.
  EOT

  type    = set(string)
  default = []
}