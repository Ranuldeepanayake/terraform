variable "bucket_name" {
  description = "Name of the S3 bucket to create."
  type        = string
  default     = "example-general-bucket"
}

variable "force_destroy" {
  description = "Allow deleting a non-empty bucket."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the bucket."
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "cloud"
  }
}

variable "versioning_enabled" {
  description = "Enable versioning on the bucket."
  type        = bool
  default     = false
}

variable "object_ownership" {
  description = "Whether the bucket is privately owned or not."
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "acl" {
  description = "Canned ACL to apply to the bucket."
  type        = string
  default     = "private"
}

variable "bucket_policy" {
  description = "Optional JSON-encoded bucket policy document to attach to the bucket."
  type        = any
  default     = null
}

variable "aws_region" {
  description = "AWS region for the provider."
  type        = string
  default     = "ap-southeast-1"
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
