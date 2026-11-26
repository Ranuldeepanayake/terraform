# Manage bucket versioning independently so it can be enabled or suspended without replacing the bucket.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Enforce the requested object ownership mode before optionally configuring ACLs.
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

# Apply a canned ACL only when ownership controls allow ACLs.
resource "aws_s3_bucket_acl" "this" {
  count = var.object_ownership == "BucketOwnerEnforced" ? 0 : 1

  depends_on = [aws_s3_bucket_ownership_controls.this]

  bucket = aws_s3_bucket.this.id
  acl    = var.acl
}

# Configure the bucket-level controls that block public ACLs and policies.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = var.block_public_access.block_public_acls
  block_public_policy     = var.block_public_access.block_public_policy
  ignore_public_acls      = var.block_public_access.ignore_public_acls
  restrict_public_buckets = var.block_public_access.restrict_public_buckets
}

# Attach the caller's policy and any generated CloudFront OAC read grants.
resource "aws_s3_bucket_policy" "this" {
  count  = local.effective_bucket_policy_document == null ? 0 : 1
  bucket = aws_s3_bucket.this.id
  policy = local.bucket_policy_json

  lifecycle {
    precondition {
      condition = try(
        local.effective_bucket_policy_document.Version != null &&
        local.effective_bucket_policy_document.Statement != null,
        false
      )
      error_message = "bucket_policy must be a valid IAM policy document with Version and Statement fields; pass an HCL object or JSON string."
    }
  }
}

# Set default server-side encryption, including optional KMS encryption and Bucket Keys.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.server_side_encryption.enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.server_side_encryption.algorithm
      kms_master_key_id = var.server_side_encryption.kms_master_key_id
    }

    bucket_key_enabled = var.server_side_encryption.algorithm == "AES256" ? null : var.server_side_encryption.bucket_key_enabled
  }
}
