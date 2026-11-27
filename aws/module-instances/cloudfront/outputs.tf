output "distribution_id" {
  description = "Imported CloudFront distribution ID."
  value       = module.cloudfront.distribution_id
}

output "distribution_arn" {
  description = "Imported CloudFront distribution ARN."
  value       = module.cloudfront.distribution_arn
}

output "domain_name" {
  description = "CloudFront distribution domain name."
  value       = module.cloudfront.domain_name
}

output "distribution_url" {
  description = "HTTPS URL for the CloudFront distribution."
  value       = module.cloudfront.distribution_url
}

output "aliases" {
  description = "Alternate domain names configured on the distribution."
  value       = module.cloudfront.aliases
}

output "enabled" {
  description = "Whether the distribution is enabled."
  value       = module.cloudfront.enabled
}

output "origins" {
  description = "Origins attached to the distribution, keyed by origin ID."
  value       = module.cloudfront.origins
}

output "certificate_arn" {
  description = "ACM certificate ARN attached to the distribution."
  value       = module.cloudfront.certificate_arn
}

output "effective_oac_ids" {
  description = "OAC IDs configured for S3 origins."
  value       = module.cloudfront.effective_oac_ids
}

output "effective_behavior_policy_ids" {
  description = "Effective policy IDs for the default and ordered cache behaviors."
  value       = module.cloudfront.effective_behavior_policy_ids
}

output "etag" {
  description = "Current ETag for the distribution configuration."
  value       = module.cloudfront.etag
}

output "last_modified_time" {
  description = "Timestamp when the distribution configuration was last modified."
  value       = module.cloudfront.last_modified_time
}

output "cloudwatch_log_export_enabled" {
  description = "Whether CloudFront standard access logs are delivered to CloudWatch Logs."
  value       = module.cloudfront.cloudwatch_log_export_enabled
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group receiving CloudFront access logs, or null when export is disabled."
  value       = module.cloudfront.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group, or null when export is disabled."
  value       = module.cloudfront.cloudwatch_log_group_arn
}

output "cloudwatch_log_delivery_source_name" {
  description = "CloudWatch Logs delivery source name, or null when export is disabled."
  value       = module.cloudfront.cloudwatch_log_delivery_source_name
}

output "cloudwatch_log_delivery_destination_name" {
  description = "CloudWatch Logs delivery destination name, or null when export is disabled."
  value       = module.cloudfront.cloudwatch_log_delivery_destination_name
}

output "cloudwatch_log_delivery_id" {
  description = "CloudWatch Logs delivery ID, or null when export is disabled."
  value       = module.cloudfront.cloudwatch_log_delivery_id
}

output "route53_record_fqdns" {
  description = "Fully qualified DNS names managed by the caller."
  value       = module.cloudfront.route53_record_fqdns
}
