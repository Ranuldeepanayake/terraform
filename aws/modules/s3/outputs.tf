output "bucket_id" {
  description = "The name of the bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_name" {
  description = "The name of the created bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_objects_arn" {
  description = "ARN pattern covering every object in the bucket."
  value       = "${aws_s3_bucket.this.arn}/*"
}

output "bucket_domain_name" {
  description = "The bucket domain name."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket regional domain name."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "AWS Region where the bucket is located."
  value       = aws_s3_bucket.this.region
}

output "bucket_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the bucket's regional endpoint."
  value       = aws_s3_bucket.this.hosted_zone_id
}

output "bucket_versioning_status" {
  description = "Configured bucket versioning status."
  value       = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}

output "bucket_encryption" {
  description = "Configured default server-side encryption settings, or null if disabled."
  value       = try(aws_s3_bucket_server_side_encryption_configuration.this[0].rule, null)
}

output "bucket_public_access_block" {
  description = "Configured public access block values."
  value = {
    block_public_acls       = aws_s3_bucket_public_access_block.this.block_public_acls
    block_public_policy     = aws_s3_bucket_public_access_block.this.block_public_policy
    ignore_public_acls      = aws_s3_bucket_public_access_block.this.ignore_public_acls
    restrict_public_buckets = aws_s3_bucket_public_access_block.this.restrict_public_buckets
  }
}

output "bucket_object_ownership" {
  description = "Configured S3 object ownership mode."
  value       = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership
}

output "bucket_acl" {
  description = "Configured bucket ACL, or null when BucketOwnerEnforced ownership disables ACLs."
  value       = try(aws_s3_bucket_acl.this[0].acl, null)
}

output "bucket_tags" {
  description = "Tags applied to the bucket, including the module-managed name tag."
  value       = aws_s3_bucket.this.tags
}

output "bucket_lifecycle_rule_ids" {
  description = "IDs of lifecycle rules managed by this module."
  value       = try([for rule in aws_s3_bucket_lifecycle_configuration.this[0].rule : rule.id], [])
}

output "bucket_logging_configuration" {
  description = "Configured server access logging destination, or null when logging is disabled."
  value = try({
    target_bucket = aws_s3_bucket_logging.this[0].target_bucket
    target_prefix = aws_s3_bucket_logging.this[0].target_prefix
  }, null)
}

output "bucket_policy_id" {
  description = "The ID of the attached bucket policy, if any."
  value       = try(aws_s3_bucket_policy.this[0].id, null)
}

output "bucket_website_endpoint" {
  description = "Static website endpoint, or null when website hosting is disabled."
  value       = try(aws_s3_bucket_website_configuration.this[0].website_endpoint, null)
}

output "bucket_website_domain" {
  description = "Static website domain name, or null when website hosting is disabled."
  value       = try(aws_s3_bucket_website_configuration.this[0].website_domain, null)
}

output "bucket_website_enabled" {
  description = "Whether static website hosting is enabled."
  value       = var.enable_static_hosting
}

output "bucket_website_index_document" {
  description = "Configured website index document, or null when website hosting is disabled."
  value       = try(aws_s3_bucket_website_configuration.this[0].index_document[0].suffix, null)
}

output "bucket_website_error_document" {
  description = "Configured website error document, or null when unset or website hosting is disabled."
  value       = try(aws_s3_bucket_website_configuration.this[0].error_document[0].key, null)
}

output "bucket_website_object_keys" {
  description = "Object keys uploaded by this module for the static website."
  value       = keys(aws_s3_object.website_files)
}

output "bucket_acceleration_status" {
  description = "Transfer Acceleration status, or null when it is disabled."
  value       = try(aws_s3_bucket_accelerate_configuration.this[0].status, null)
}

output "bucket_request_payer" {
  description = "Configured request payer setting, or null when not managed."
  value       = try(aws_s3_bucket_request_payment_configuration.this[0].payer, null)
}
