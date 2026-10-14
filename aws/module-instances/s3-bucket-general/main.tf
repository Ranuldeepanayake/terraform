resource "random_string" "bucket_suffix" {
  length  = 10
  upper   = false
  special = false
}

locals {
  aws_region            = "ap-southeast-1"
  bucket_name_prefix    = "s3-app"
  generated_bucket_name = "${local.bucket_name_prefix}-${random_string.bucket_suffix.result}"

  tags = {
    resource-type = "s3-bucket"
    project       = "s3-app"
    environment   = "dev"
    managed-by    = "terraform"
  }
}

module "s3_bucket_general" {
  source = "../../modules/s3"

  bucket_name        = local.generated_bucket_name
  force_destroy      = false
  versioning_enabled = false
  object_ownership   = "BucketOwnerEnforced"
  acl                = "private"

  # This allows website content to be read publicly. Review before changing the policy.
  bucket_policy = file("${path.module}/policies/bucket-policy.json")
  block_public_access = {
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
  }

  server_side_encryption = {
    # The existing Terraform state does not manage an encryption configuration.
    # S3 applies SSE-S3 by default, so leave this resource unmanaged.
    enabled            = false
    algorithm          = "AES256"
    kms_master_key_id  = null
    bucket_key_enabled = true
  }

  lifecycle_rules               = []
  cors_rules                    = []
  logging_configuration         = null
  transfer_acceleration_enabled = false
  request_payer                 = null

  # Set enable_static_hosting=true and configure website_configuration/files to host a site.
  # Website hosting remains disabled to avoid enabling public hosting by default.
  enable_static_hosting = false
  website_configuration = null
  website_files         = {}

  tags = local.tags
}
