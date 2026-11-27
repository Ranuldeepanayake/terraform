variable "vpc_id" {
  description = "ID of the VPC to attach the internet gateway to."
  type        = string
}

variable "name" {
  description = "Optional Name tag for the internet gateway."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || length(trimspace(var.name)) > 0
    error_message = "name must be a non-empty string when provided."
  }
}

variable "tags" {
  description = "Additional tags to apply to the internet gateway. ResourceType is managed by this module."
  type        = map(string)
  default     = {}
}