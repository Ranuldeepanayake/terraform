# Create the S3 bucket with the requested name and tags.
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    {
      name = var.bucket_name
    },
    var.tags
  )
}

# Enable or disable versioning based on the module input.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Configure object ownership rules for the bucket.
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

#Skip ACL if set to "BucketOwnerEnforced" as per AWS recommendation for S3 buckets with Object Ownership set to BucketOwnerEnforced.
resource "aws_s3_bucket_acl" "this" {
  count = var.object_ownership == "BucketOwnerEnforced" ? 0 : 1

  depends_on = [aws_s3_bucket_ownership_controls.this]

  bucket = aws_s3_bucket.this.id
  acl    = var.acl
}

# Control whether public ACLs and policies are allowed on the bucket.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = var.block_public_access.block_public_acls
  block_public_policy     = var.block_public_access.block_public_policy
  ignore_public_acls      = var.block_public_access.ignore_public_acls
  restrict_public_buckets = var.block_public_access.restrict_public_buckets
}

# Template for the bucket policy, replacing the placeholder bucket name with the actual bucket name.
locals {
  policy_document = try(var.bucket_policy.bucket_policy, var.bucket_policy)

  rendered_bucket_policy = var.bucket_policy != null ? {
    Version = try(local.policy_document.Version, null)
    Statement = [for statement in try(local.policy_document.Statement, []) : {
      Sid       = try(statement.Sid, null)
      Effect    = statement.Effect
      Principal = statement.Principal
      Action    = statement.Action
      Resource  = [for resource in flatten([statement.Resource]) : replace(resource, "placeholder-bucket", var.bucket_name)]
    }]
  } : null
}

# Attach an optional bucket policy when one is provided. 'count' skips creating the resource if the value is 0.
resource "aws_s3_bucket_policy" "this" {
  count  = local.rendered_bucket_policy != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = jsonencode(local.rendered_bucket_policy)
}
