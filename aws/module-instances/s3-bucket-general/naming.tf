# Generate the suffix used to make this caller's S3 bucket name globally unique.
resource "random_string" "bucket_suffix" {
  length  = 10
  upper   = false
  special = false
}
