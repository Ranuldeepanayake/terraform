output "bucket_id" {
  description = "Created bucket ID (name)."
  value       = module.s3_bucket_general.bucket_id
}

output "bucket_name" {
  description = "Created bucket name."
  value       = module.s3_bucket_general.bucket_name
}

output "bucket_arn" {
  description = "Created bucket ARN."
  value       = module.s3_bucket_general.bucket_arn
}

output "bucket_objects_arn" {
  description = "ARN pattern covering every object in the bucket."
  value       = module.s3_bucket_general.bucket_objects_arn
}

output "bucket_domain_name" {
  description = "Bucket's legacy global domain name."
  value       = module.s3_bucket_general.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Bucket's regional domain name."
  value       = module.s3_bucket_general.bucket_regional_domain_name
}

output "bucket_region" {
  description = "AWS Region where the bucket is located."
  value       = module.s3_bucket_general.bucket_region
}

output "bucket_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the bucket's regional endpoint."
  value       = module.s3_bucket_general.bucket_hosted_zone_id
}

output "bucket_versioning_status" {
  description = "Configured versioning state."
  value       = module.s3_bucket_general.bucket_versioning_status
}

output "bucket_encryption" {
  description = "Configured default encryption settings, or null if disabled."
  value       = module.s3_bucket_general.bucket_encryption
}

output "bucket_public_access_block" {
  description = "Configured S3 public access block settings."
  value       = module.s3_bucket_general.bucket_public_access_block
}

output "bucket_object_ownership" {
  description = "Configured S3 object ownership mode."
  value       = module.s3_bucket_general.bucket_object_ownership
}

output "bucket_acl" {
  description = "Configured bucket ACL, or null when ACLs are disabled."
  value       = module.s3_bucket_general.bucket_acl
}

output "bucket_tags" {
  description = "Tags applied to the bucket."
  value       = module.s3_bucket_general.bucket_tags
}

output "bucket_lifecycle_rule_ids" {
  description = "IDs of lifecycle rules managed by this module."
  value       = module.s3_bucket_general.bucket_lifecycle_rule_ids
}

output "bucket_logging_configuration" {
  description = "Configured access logging destination, or null when disabled."
  value       = module.s3_bucket_general.bucket_logging_configuration
}

output "server_access_logging_enabled" {
  description = "Whether S3 server access logs are delivered to an S3 bucket."
  value       = module.s3_bucket_general.server_access_logging_enabled
}

output "cloudwatch_log_export_enabled" {
  description = "Whether S3 server access logs are exported to CloudWatch Logs."
  value       = module.s3_bucket_general.cloudwatch_log_export_enabled
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group receiving exported S3 access logs, or null when disabled."
  value       = module.s3_bucket_general.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN, or null when export is disabled."
  value       = module.s3_bucket_general.cloudwatch_log_group_arn
}

output "cloudwatch_log_delivery_id" {
  description = "CloudWatch log delivery ID, or null when export is disabled."
  value       = module.s3_bucket_general.cloudwatch_log_delivery_id
}

output "bucket_policy_id" {
  description = "Bucket policy resource ID, or null if no policy is configured."
  value       = module.s3_bucket_general.bucket_policy_id
}

output "bucket_website_endpoint" {
  description = "Static website endpoint, or null when website hosting is disabled."
  value       = module.s3_bucket_general.bucket_website_endpoint
}

output "bucket_website_domain" {
  description = "Static website domain name, or null when website hosting is disabled."
  value       = module.s3_bucket_general.bucket_website_domain
}

output "bucket_website_enabled" {
  description = "Whether static website hosting is enabled."
  value       = module.s3_bucket_general.bucket_website_enabled
}

output "bucket_website_index_document" {
  description = "Configured website index document, or null when hosting is disabled."
  value       = module.s3_bucket_general.bucket_website_index_document
}

output "bucket_website_error_document" {
  description = "Configured website error document, or null when unset or hosting is disabled."
  value       = module.s3_bucket_general.bucket_website_error_document
}

output "bucket_website_object_keys" {
  description = "Website object keys uploaded from the caller's site subdirectory."
  value       = module.s3_bucket_general.bucket_website_object_keys
}

output "bucket_acceleration_status" {
  description = "Transfer Acceleration status, or null when disabled."
  value       = module.s3_bucket_general.bucket_acceleration_status
}

output "bucket_request_payer" {
  description = "Configured request payer."
  value       = module.s3_bucket_general.bucket_request_payer
}

output "bucket_summary" {
  description = "Bucket identity, endpoints, tags, access settings, and CloudFront read grants."
  value       = module.s3_bucket_general.bucket_summary
}

output "cloudfront_distribution_arns" {
  description = "CloudFront distributions granted object-read access to this bucket."
  value       = module.s3_bucket_general.cloudfront_distribution_arns
}
