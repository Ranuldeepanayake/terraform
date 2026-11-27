# Manage the general-purpose S3 bucket and its optional features through the shared module.
module "s3_bucket_general" {
  source = "../../modules/s3"

  bucket_name        = local.generated_bucket_name
  force_destroy      = true
  versioning_enabled = false
  object_ownership   = "BucketOwnerEnforced"
  acl                = "private"

  # This allows website content to be read publicly. Review before changing the policy.
  bucket_policy = file("${path.module}/policies/bucket-policy.json")
  cloudfront_distribution_arns = [
    "arn:aws:cloudfront::104322896078:distribution/E1BDLID84MOL0G"
  ]

  block_public_access = {
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
  }

  server_side_encryption = {
    enabled            = true
    algorithm          = "AES256"
    kms_master_key_id  = null
    bucket_key_enabled = false
  }

  lifecycle_rules              = []
  cors_rules                   = []

  enable_server_access_logging = true
  logging_configuration = {
    target_bucket = local.generated_bucket_name
    target_prefix = "logs/bucket-logs "
  }
  cloudwatch_log_export_enabled    = true
  cloudwatch_log_group_name        = null
  cloudwatch_log_retention_in_days = 7

  transfer_acceleration_enabled = false
  request_payer                 = "BucketOwner"

  # Set enable_static_hosting=true and configure website_configuration/files to host a site.
  # Website hosting remains disabled to avoid enabling public hosting by default.
  enable_static_hosting = false
  website_configuration = null
  website_files         = {}

  tags = local.tags
}
