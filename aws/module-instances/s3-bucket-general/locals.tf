# Generate a globally unique bucket name and keep common tags in one place.
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
