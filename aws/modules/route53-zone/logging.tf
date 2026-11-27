# Store public DNS query logs in the region required by Route 53.
resource "aws_cloudwatch_log_group" "route53_query_logs" {
  count             = var.enable_query_logging ? 1 : 0
  provider          = aws.us_east_1
  name              = local.query_log_group_name
  retention_in_days = var.query_log_retention_in_days
  tags              = var.tags
}

# Permit the Route 53 service to write query log streams to this specific group.
resource "aws_cloudwatch_log_resource_policy" "route53_query_logs" {
  count        = var.enable_query_logging ? 1 : 0
  provider     = aws.us_east_1
  resource_arn = aws_cloudwatch_log_group.route53_query_logs[0].arn
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "route53.amazonaws.com"
      }
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.route53_query_logs[0].arn}:*"
    }]
  })
}

# Connect the public hosted zone to the CloudWatch Logs destination.
resource "aws_route53_query_log" "this" {
  count                    = var.enable_query_logging ? 1 : 0
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs[0].arn
  zone_id                  = aws_route53_zone.this.zone_id

  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logs]

  lifecycle {
    precondition {
      condition     = !var.private_zone
      error_message = "Route 53 DNS query logging is supported only for public hosted zones."
    }
  }
}
