# Select only origins that should be attached to the distribution.
locals {
  enabled_origins = {
    for key, origin in var.origins : key => origin if try(origin.enabled, true)
  }

  s3_origins = {
    for key, origin in local.enabled_origins : key => origin
    if try(origin.s3_bucket_name, null) != null
  }

  # Prefer the validated managed certificate, falling back to an existing ARN when supplied.
  effective_certificate_arn = var.create_acm_certificate ? aws_acm_certificate_validation.this[0].certificate_arn : var.viewer_certificate.acm_certificate_arn

  # Resolve configured behavior policy names to IDs while preserving externally supplied IDs.
  effective_behavior_policy_ids = merge(
    {
      default = {
        cache_policy_id = var.default_behavior.cache_policy_id != null ? var.default_behavior.cache_policy_id : try(
          aws_cloudfront_cache_policy.managed[var.default_behavior.cache_policy_name].id,
          null
        )
        origin_request_policy_id = var.default_behavior.origin_request_policy_id != null ? var.default_behavior.origin_request_policy_id : try(
          aws_cloudfront_origin_request_policy.managed[var.default_behavior.origin_request_policy_name].id,
          null
        )
        response_headers_policy_id = var.default_behavior.response_headers_policy_id != null ? var.default_behavior.response_headers_policy_id : try(
          aws_cloudfront_response_headers_policy.managed[var.default_behavior.response_headers_policy_name].id,
          null
        )
      }
    },
    {
      for behavior in var.ordered_cache_behaviors : behavior.path_pattern => {
        cache_policy_id = behavior.cache_policy_id != null ? behavior.cache_policy_id : try(
          aws_cloudfront_cache_policy.managed[behavior.cache_policy_name].id,
          null
        )
        origin_request_policy_id = behavior.origin_request_policy_id != null ? behavior.origin_request_policy_id : try(
          aws_cloudfront_origin_request_policy.managed[behavior.origin_request_policy_name].id,
          null
        )
        response_headers_policy_id = behavior.response_headers_policy_id != null ? behavior.response_headers_policy_id : try(
          aws_cloudfront_response_headers_policy.managed[behavior.response_headers_policy_name].id,
          null
        )
      }
    }
  )
}

# Resolve the provider region so generated S3 origin hostnames use the bucket's regional endpoint.
data "aws_region" "current" {}
