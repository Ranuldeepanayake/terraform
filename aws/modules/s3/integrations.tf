# Send S3 server access logs to a separately managed destination bucket.
resource "aws_s3_bucket_logging" "this" {
  count  = local.server_access_logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_configuration.target_bucket
  target_prefix = var.logging_configuration.target_prefix

  target_object_key_format {
    simple_prefix {}
  }
}

# Create the CloudWatch Logs group only when S3 log export is enabled.
resource "aws_cloudwatch_log_group" "s3_server_access_logs" {
  count             = var.cloudwatch_log_export_enabled ? 1 : 0
  name              = local.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_retention_in_days
  tags              = var.tags
}

# Register this bucket as an S3 server-access-log source in CloudWatch Logs.
resource "aws_cloudwatch_log_delivery_source" "s3_server_access_logs" {
  count        = var.cloudwatch_log_export_enabled ? 1 : 0
  name         = "${local.cloudwatch_delivery_name}-source"
  log_type     = "S3_SERVER_ACCESS_LOGS"
  resource_arn = aws_s3_bucket.this.arn
  tags         = var.tags
}

# Connect the S3 access-log delivery destination to the configured log group.
resource "aws_cloudwatch_log_delivery_destination" "s3_server_access_logs" {
  count         = var.cloudwatch_log_export_enabled ? 1 : 0
  name          = "${local.cloudwatch_delivery_name}-destination"
  output_format = "json"
  tags          = var.tags

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.s3_server_access_logs[0].arn
  }
}

# Start delivering the registered S3 server-access logs to CloudWatch Logs.
resource "aws_cloudwatch_log_delivery" "s3_server_access_logs" {
  count                    = var.cloudwatch_log_export_enabled ? 1 : 0
  delivery_source_name     = aws_cloudwatch_log_delivery_source.s3_server_access_logs[0].name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.s3_server_access_logs[0].arn
  tags                     = var.tags
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
