resource "random_string" "bucket_suffix" {
  length  = 10
  upper   = false
  special = false
}

locals {
  generated_bucket_name = "${var.bucket_name}-${random_string.bucket_suffix.result}"
}

module "s3_bucket_general" {
  source = "../../modules/s3"

  bucket_name        = local.generated_bucket_name
  force_destroy      = var.force_destroy
  tags               = var.tags
  versioning_enabled = var.versioning_enabled
  object_ownership   = var.object_ownership
  acl                = var.acl
  bucket_policy      = var.bucket_policy
  aws_region         = var.aws_region
  block_public_access = {
    block_public_acls       = var.block_public_access.block_public_acls
    block_public_policy     = var.block_public_access.block_public_policy
    ignore_public_acls      = var.block_public_access.ignore_public_acls
    restrict_public_buckets = var.block_public_access.restrict_public_buckets
  }
}
