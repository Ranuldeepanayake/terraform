output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_url" {
  description = "HTTPS URL for the default CloudFront distribution domain."
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "aliases" {
  description = "Alternate domain names configured on the distribution."
  value       = aws_cloudfront_distribution.this.aliases
}

output "enabled" {
  description = "Whether the CloudFront distribution is enabled."
  value       = aws_cloudfront_distribution.this.enabled
}

output "origins" {
  description = "Origins attached to the distribution, keyed by origin ID and containing their domain names."
  value = {
    for origin in aws_cloudfront_distribution.this.origin :
    origin.origin_id => origin.domain_name
  }
}

output "hosted_zone_id" {
  description = "CloudFront Route 53 hosted zone ID."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "status" {
  description = "CloudFront distribution deployment status."
  value       = aws_cloudfront_distribution.this.status
}

output "etag" {
  description = "Current ETag for the CloudFront distribution configuration."
  value       = aws_cloudfront_distribution.this.etag
}

output "last_modified_time" {
  description = "Timestamp when the CloudFront distribution configuration was last modified."
  value       = aws_cloudfront_distribution.this.last_modified_time
}

output "cloudwatch_log_export_enabled" {
  description = "Whether CloudFront standard access logs are delivered to CloudWatch Logs."
  value       = var.cloudwatch_log_export_enabled
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group receiving CloudFront access logs, or null when export is disabled."
  value       = var.cloudwatch_log_export_enabled ? aws_cloudwatch_log_group.cloudfront_access_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group receiving CloudFront access logs, or null when export is disabled."
  value       = try(aws_cloudwatch_log_group.cloudfront_access_logs[0].arn, null)
}

output "cloudwatch_log_delivery_source_name" {
  description = "Name of the CloudWatch delivery source, or null when export is disabled."
  value       = try(aws_cloudwatch_log_delivery_source.cloudfront_access_logs[0].name, null)
}

output "cloudwatch_log_delivery_destination_name" {
  description = "Name of the CloudWatch delivery destination, or null when export is disabled."
  value       = try(aws_cloudwatch_log_delivery_destination.cloudfront_access_logs[0].name, null)
}

output "cloudwatch_log_delivery_id" {
  description = "CloudWatch Logs delivery ID for CloudFront access logs, or null when export is disabled."
  value       = try(aws_cloudwatch_log_delivery.cloudfront_access_logs[0].id, null)
}

output "certificate_arn" {
  description = "ACM certificate ARN attached to the distribution, or null when using the default certificate."
  value       = local.effective_certificate_arn
}

output "route53_record_fqdns" {
  description = "Fully qualified DNS record names created for the distribution aliases."
  value = concat(
    [for record in values(aws_route53_record.distribution_a_alias) : record.fqdn],
    [for record in values(aws_route53_record.distribution_aaaa_alias) : record.fqdn],
    [for record in values(aws_route53_record.distribution_cname) : record.fqdn]
  )
}

output "oac_ids" {
  description = "Origin Access Control IDs created by this module, keyed by origin ID."
  value       = { for k, v in aws_cloudfront_origin_access_control.this : k => v.id }
}

output "effective_oac_ids" {
  description = "OAC IDs configured for S3 origins, including OACs created by this module and externally managed OACs."
  value = {
    for key, origin in local.s3_origins :
    key => (try(origin.create_oac, true) ? try(aws_cloudfront_origin_access_control.this[key].id, null) : try(origin.origin_access_control_id, null))
  }
}

output "effective_behavior_policy_ids" {
  description = "Effective cache, origin-request, and response-header policy IDs for the default and ordered behaviors."
  value       = local.effective_behavior_policy_ids
}

output "cache_policy_ids" {
  description = "IDs of cache policies created by this module, keyed by configured policy name."
  value       = { for k, v in aws_cloudfront_cache_policy.managed : k => v.id }
}

output "origin_request_policy_ids" {
  description = "IDs of origin request policies created by this module."
  value       = { for k, v in aws_cloudfront_origin_request_policy.managed : k => v.id }
}

output "response_headers_policy_ids" {
  description = "IDs of response headers policies created by this module."
  value       = { for k, v in aws_cloudfront_response_headers_policy.managed : k => v.id }
}
