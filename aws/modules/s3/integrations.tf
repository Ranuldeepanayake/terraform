# Send S3 server access logs to a separately managed destination bucket.
resource "aws_s3_bucket_logging" "this" {
  count  = var.logging_configuration == null ? 0 : 1
  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_configuration.target_bucket
  target_prefix = var.logging_configuration.target_prefix

  target_object_key_format {
    simple_prefix {}
  }
}

# Enable S3 Transfer Acceleration when requested.
resource "aws_s3_bucket_accelerate_configuration" "this" {
  count  = var.transfer_acceleration_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id
  status = "Enabled"
}

# Configure which party pays eligible S3 request charges when explicitly set.
resource "aws_s3_bucket_request_payment_configuration" "this" {
  count  = var.request_payer == null ? 0 : 1
  bucket = aws_s3_bucket.this.id
  payer  = var.request_payer
}
