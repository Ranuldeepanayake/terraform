# AWS region used by the provider configuration.
variable "aws_region" {
  description = "AWS region to use for the provider."
  type        = string
  default     = "ap-southeast-1"
}

# Name of the S3 bucket to create.
variable "bucket_name" {
  description = "Name of the S3 bucket to create."
  type        = string

  validation {
    condition = (
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name)) &&
      !strcontains(var.bucket_name, "..")
    )
    error_message = "bucket_name must be 3-63 characters, use lowercase letters, numbers, dots, or hyphens, start and end with a letter or number, and not contain consecutive dots."
  }
}

variable "force_destroy" {
  description = "Whether to allow deleting a non-empty bucket."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the bucket."
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Enable versioning on the bucket."
  type        = bool
  default     = false
}

# Controls whether S3 object ownership is enforced or preferred.
variable "object_ownership" {
  description = "S3 object ownership mode."
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.object_ownership)
    error_message = "object_ownership must be BucketOwnerEnforced, BucketOwnerPreferred, or ObjectWriter."
  }
}

variable "acl" {
  description = "Canned ACL to apply to the bucket."
  type        = string
  default     = "private"

  validation {
    condition = contains([
      "private",
      "public-read",
      "public-read-write",
      "authenticated-read",
      "aws-exec-read",
      "bucket-owner-read",
      "bucket-owner-full-control"
    ], var.acl)
    error_message = "acl must be one of the supported S3 canned ACL values."
  }
}

variable "block_public_access" {
  description = "Public access block settings for the bucket."
  type = object({
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "bucket_policy" {
  description = "Optional IAM policy document as an HCL object or JSON string."
  type        = any
  default     = null
}

variable "server_side_encryption" {
  description = "Default server-side encryption configuration. Use AES256, aws:kms, or aws:kms:dsse."
  type = object({
    enabled            = optional(bool, true)
    algorithm          = optional(string, "AES256")
    kms_master_key_id  = optional(string)
    bucket_key_enabled = optional(bool, true)
  })
  default = {}

  validation {
    condition = contains(
      ["AES256", "aws:kms", "aws:kms:dsse"],
      var.server_side_encryption.algorithm
    )
    error_message = "server_side_encryption.algorithm must be AES256, aws:kms, or aws:kms:dsse."
  }

  validation {
    condition = (
      var.server_side_encryption.algorithm == "AES256" ||
      var.server_side_encryption.kms_master_key_id == null ||
      length(trimspace(var.server_side_encryption.kms_master_key_id)) > 0
    )
    error_message = "kms_master_key_id must be null or a non-empty KMS key ID or ARN."
  }

  validation {
    condition = (
      var.server_side_encryption.algorithm != "AES256" ||
      var.server_side_encryption.kms_master_key_id == null
    )
    error_message = "kms_master_key_id can only be set when using aws:kms or aws:kms:dsse."
  }
}

variable "lifecycle_rules" {
  description = "Optional S3 lifecycle rules for expiration, transitions, and incomplete multipart uploads."
  type = list(object({
    id                                     = string
    enabled                                = optional(bool, true)
    prefix                                 = optional(string)
    expiration_days                        = optional(number)
    expired_object_delete_marker           = optional(bool)
    noncurrent_version_expiration_days     = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules :
      (rule.expiration_days == null || rule.expiration_days >= 1) &&
      !(rule.expiration_days != null && rule.expired_object_delete_marker == true) &&
      (rule.noncurrent_version_expiration_days == null || rule.noncurrent_version_expiration_days >= 1) &&
      (rule.abort_incomplete_multipart_upload_days == null || rule.abort_incomplete_multipart_upload_days >= 1) &&
      alltrue([for transition in rule.transitions : transition.days >= 0])
    ])
    error_message = "Lifecycle days must be non-negative; expiration and cleanup day values must be at least 1."
  }

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules :
      rule.expiration_days != null ||
      rule.expired_object_delete_marker == true ||
      rule.noncurrent_version_expiration_days != null ||
      rule.abort_incomplete_multipart_upload_days != null ||
      length(rule.transitions) > 0
    ])
    error_message = "Each lifecycle rule must configure at least one expiration, transition, or multipart cleanup action."
  }
}

variable "cors_rules" {
  description = "Optional Cross-Origin Resource Sharing rules for browser clients."
  type = list(object({
    allowed_headers = optional(list(string), [])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.cors_rules :
      length(rule.allowed_methods) > 0 &&
      length(rule.allowed_origins) > 0 &&
      alltrue([for method in rule.allowed_methods : contains(["GET", "PUT", "POST", "DELETE", "HEAD"], method)])
    ])
    error_message = "Each CORS rule needs allowed_methods and allowed_origins; methods must be GET, PUT, POST, DELETE, or HEAD."
  }
}

variable "enable_static_hosting" {
  description = "Enable S3 static website hosting. Requires website_configuration; S3 website endpoints are public HTTP endpoints and do not support HTTPS directly."
  type        = bool
  default     = false
}

variable "website_configuration" {
  description = "Optional static website configuration. Website endpoints are public HTTP endpoints and do not support HTTPS directly."
  type = object({
    index_document = optional(string)
    error_document = optional(string)
    redirect_all_requests_to = optional(object({
      host_name = string
      protocol  = optional(string)
    }))
  })
  default  = null
  nullable = true

  validation {
    condition = var.website_configuration == null || (
      (
        var.website_configuration.redirect_all_requests_to != null &&
        var.website_configuration.index_document == null &&
        var.website_configuration.error_document == null
        ) || (
        var.website_configuration.redirect_all_requests_to == null &&
        var.website_configuration.index_document != null
      )
    )
    error_message = "Configure either index_document (optionally with error_document) or redirect_all_requests_to, but not both."
  }
}

variable "website_files" {
  description = "Optional map of website object keys to caller-local files and optional HTTP metadata."
  type = map(object({
    source        = string
    content_type  = optional(string)
    cache_control = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, file in var.website_files :
      length(key) > 0 &&
      !startswith(key, "/") &&
      !contains(split("/", key), "..") &&
      !strcontains(key, "\\") &&
      length(trimspace(file.source)) > 0
    ])
    error_message = "Website object keys must be non-empty relative paths without parent-directory segments, and each source path must be non-empty."
  }
}

variable "logging_configuration" {
  description = "Optional server access logging destination. The destination bucket must exist and allow S3 log delivery."
  type = object({
    target_bucket = string
    target_prefix = optional(string, "")
  })
  default  = null
  nullable = true
}

variable "transfer_acceleration_enabled" {
  description = "Enable S3 Transfer Acceleration for the bucket."
  type        = bool
  default     = false
}

variable "request_payer" {
  description = "Optional request-payer configuration. Leave null to avoid managing this setting."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.request_payer == null || contains(["BucketOwner", "Requester"], var.request_payer)
    error_message = "request_payer must be null, BucketOwner, or Requester."
  }
}
