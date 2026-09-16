variable "name" {
  description = "Name of the IAM policy."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The IAM policy name must not be empty."
  }
}

variable "description" {
  description = "Description of the IAM policy."
  type        = string
  default     = null
}

variable "policy" {
  description = "Policy document for the IAM policy in JSON format."
  type        = string

  validation {
    condition     = can(jsondecode(var.policy))
    error_message = "The policy variable must contain a valid JSON IAM policy document."
  }
}

variable "path" {
  description = "IAM path under which the policy is created."
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags to apply to the IAM policy."
  type        = map(string)
  default     = {}
}