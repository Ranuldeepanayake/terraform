output "bucket_id" {
  description = "The name of the bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket regional domain name."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_policy_id" {
  description = "The ID of the attached bucket policy, if any."
  value       = try(aws_s3_bucket_policy.this[0].id, null)
}
