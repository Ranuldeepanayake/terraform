variable "name" {
  description = "Name of the IAM role."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The IAM role name must not be empty."
  }
}

variable "description" {
  description = "Description of the IAM role."
  type        = string
  default     = null
}

variable "path" {
  description = "IAM path under which the role is created."
  type        = string
  default     = "/"
}

variable "trust_policy" {
  description = <<-EOT
    IAM trust policy for the role in JSON format. The caller can provide this either from a JSON file using file()
    or from an aws_iam_policy_document using its .json attribute.
  EOT

  type = string
  validation {
    condition     = can(jsondecode(var.trust_policy))
    error_message = "assume_role_policy must contain a valid JSON policy document."
  }
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the IAM role."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "force_detach_policies" {
  description = "Whether to force detach policies before deleting the IAM role."
  type        = bool
  default     = false
}

variable "permissions_boundary" {
  description = "ARN of the IAM policy to use as the permissions boundary."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the IAM role."
  type        = map(string)
  default     = {}
}