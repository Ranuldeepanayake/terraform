# Repository type controls which ECR API and resource this module manages.
variable "repository_type" {
  description = "Repository type to create: private or public."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public"], var.repository_type)
    error_message = "repository_type must be private or public."
  }
}

# Name of the ECR repository; private names may include namespace path segments.
variable "name" {
  description = "Name of the ECR repository."
  type        = string
}

# Private repository settings. Public repositories must use these defaults.
variable "image_tag_mutability" {
  description = "Private repository tag mutability: MUTABLE or IMMUTABLE."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image vulnerability scanning on push for private repositories."
  type        = bool
  default     = false
}

variable "encryption_type" {
  description = "Private repository encryption type: AES256 or KMS."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS."
  }
}

variable "kms_key" {
  description = "KMS key ARN or ID used when encryption_type is KMS."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key == null || var.encryption_type == "KMS"
    error_message = "kms_key can only be set when encryption_type is KMS."
  }
}

variable "force_delete" {
  description = "Allow deletion of a private repository that still contains images."
  type        = bool
  default     = false
}

variable "lifecycle_policy" {
  description = "Optional JSON lifecycle policy for a private repository."
  type        = string
  default     = null
}

# An optional policy document that grants access to the repository.
variable "repository_policy" {
  description = "Optional JSON repository policy for a private or public repository."
  type        = string
  default     = null
}

# Public catalog metadata is optional and is only used for public repositories.
variable "catalog_data" {
  description = "Optional ECR Public catalog details."
  type = object({
    about_text        = optional(string)
    architectures     = optional(list(string))
    description       = optional(string)
    logo_image_blob   = optional(string)
    operating_systems = optional(list(string))
    usage_text        = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Tags applied to the repository, where supported."
  type        = map(string)
  default     = {}
}
