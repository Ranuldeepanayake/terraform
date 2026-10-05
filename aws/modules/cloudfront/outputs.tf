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

output "hosted_zone_id" {
  description = "CloudFront Route 53 hosted zone ID."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "status" {
  description = "CloudFront distribution deployment status."
  value       = aws_cloudfront_distribution.this.status
}

output "oac_ids" {
  description = "Origin Access Control IDs created by this module, keyed by origin ID."
  value       = { for k, v in aws_cloudfront_origin_access_control.this : k => v.id }
}

output "cache_policy_ids" {
  value = { for k, v in aws_cloudfront_cache_policy.managed : k => v.id }
}

output "origin_request_policy_ids" {
  value = { for k, v in aws_cloudfront_origin_request_policy.managed : k => v.id }
}

output "response_headers_policy_ids" {
  value = { for k, v in aws_cloudfront_response_headers_policy.managed : k => v.id }
}
