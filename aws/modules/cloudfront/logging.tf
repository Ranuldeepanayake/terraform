# Create the CloudWatch log group in us-east-1, where CloudFront logging APIs are managed.
resource "aws_cloudwatch_log_group" "cloudfront_access_logs" {
  count             = var.cloudwatch_log_export_enabled ? 1 : 0
  provider          = aws.us_east_1
  name              = local.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_retention_in_days
  tags              = var.tags
}

# Register this distribution as a CloudFront standard access-log source.
resource "aws_cloudwatch_log_delivery_source" "cloudfront_access_logs" {
  count        = var.cloudwatch_log_export_enabled ? 1 : 0
  provider     = aws.us_east_1
  name         = local.cloudwatch_delivery_source_name
  log_type     = "ACCESS_LOGS"
  resource_arn = aws_cloudfront_distribution.this.arn
  tags         = var.tags
}

# Configure the CloudWatch log group as the vended-log delivery destination.
resource "aws_cloudwatch_log_delivery_destination" "cloudfront_access_logs" {
  count                     = var.cloudwatch_log_export_enabled ? 1 : 0
  provider                  = aws.us_east_1
  name                      = local.cloudwatch_delivery_destination_name
  delivery_destination_type = "CWL"
  output_format             = "json"
  tags                      = var.tags

  delivery_destination_configuration {
    destination_resource_arn = "${aws_cloudwatch_log_group.cloudfront_access_logs[0].arn}:*"
  }
}

# Connect the distribution's access-log source to its configured destination.
resource "aws_cloudwatch_log_delivery" "cloudfront_access_logs" {
  count                    = var.cloudwatch_log_export_enabled ? 1 : 0
  provider                 = aws.us_east_1
  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudfront_access_logs[0].name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudfront_access_logs[0].arn
  tags                     = var.tags
}
