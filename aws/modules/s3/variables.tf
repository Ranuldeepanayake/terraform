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
  description = "Whether the bucket is privately owned or not."
  type        = string
  default     = "BucketOwnerEnforced"
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
    block_public_acls       = bool
    block_public_policy     = bool
    ignore_public_acls      = bool
    restrict_public_buckets = bool
  })
  default = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

# Optional IAM-style policy document passed to the bucket policy resource.
variable "bucket_policy" {
  description = "Optional IAM policy document object to attach to the bucket."
  type        = any
  default     = null
}
