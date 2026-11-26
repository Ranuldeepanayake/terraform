# Create the CloudFront distribution and attach its origins, policies, domain, and viewer certificate.
resource "aws_cloudfront_distribution" "this" {
  enabled             = var.enabled
  comment             = var.comment
  default_root_object = var.default_root_object
  aliases             = var.aliases
  price_class         = var.price_class
  http_version        = var.http_version
  is_ipv6_enabled     = var.is_ipv6_enabled
  retain_on_delete    = var.retain_on_delete
  wait_for_deployment = var.wait_for_deployment
  web_acl_id          = var.web_acl_arn

  dynamic "origin" {
    for_each = local.enabled_origins
    content {
      domain_name              = try(origin.value.domain_name, null) != null ? origin.value.domain_name : "${origin.value.s3_bucket_name}.s3.${data.aws_region.current.region}.amazonaws.com"
      origin_id                = origin.key
      origin_path              = try(origin.value.origin_path, null)
      connection_attempts      = try(origin.value.connection_attempts, 3)
      connection_timeout       = try(origin.value.connection_timeout, 10)
      origin_access_control_id = contains(keys(aws_cloudfront_origin_access_control.this), origin.key) ? aws_cloudfront_origin_access_control.this[origin.key].id : try(origin.value.origin_access_control_id, null)

      dynamic "s3_origin_config" {
        for_each = try(origin.value.s3_bucket_name, null) != null ? [1] : []
        content {
          origin_access_identity = try(origin.value.origin_access_identity_path, null) == null ? "" : origin.value.origin_access_identity_path
        }
      }

      dynamic "custom_header" {
        for_each = try(origin.value.custom_headers, [])
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "custom_origin_config" {
        for_each = try(origin.value.s3_bucket_name, null) == null ? [1] : []
        content {
          http_port                = try(origin.value.http_port, 80)
          https_port               = try(origin.value.https_port, 443)
          origin_protocol_policy   = try(origin.value.origin_protocol_policy, "https-only")
          origin_ssl_protocols     = try(origin.value.origin_ssl_protocols, ["TLSv1.2"])
          origin_keepalive_timeout = try(origin.value.origin_keepalive_timeout, 5)
          origin_read_timeout      = try(origin.value.origin_read_timeout, 30)
        }
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = var.default_behavior.target_origin_id
    viewer_protocol_policy = try(var.default_behavior.viewer_protocol_policy, "redirect-to-https")
    compress               = try(var.default_behavior.compress, true)
    allowed_methods        = try(var.default_behavior.allowed_methods, ["GET", "HEAD"])
    cached_methods         = try(var.default_behavior.cached_methods, ["GET", "HEAD"])
    smooth_streaming       = try(var.default_behavior.smooth_streaming, false)
    trusted_signers        = try(var.default_behavior.trusted_signers, [])
    trusted_key_groups     = try(var.default_behavior.trusted_key_groups, [])

    cache_policy_id = try(var.default_behavior.cache_policy_id, null) != null ? var.default_behavior.cache_policy_id : (
      try(var.default_behavior.cache_policy_name, null) != null ? aws_cloudfront_cache_policy.managed[var.default_behavior.cache_policy_name].id : null
    )
    origin_request_policy_id = try(var.default_behavior.origin_request_policy_id, null) != null ? var.default_behavior.origin_request_policy_id : (
      try(var.default_behavior.origin_request_policy_name, null) != null ? aws_cloudfront_origin_request_policy.managed[var.default_behavior.origin_request_policy_name].id : null
    )
    response_headers_policy_id = try(var.default_behavior.response_headers_policy_id, null) != null ? var.default_behavior.response_headers_policy_id : (
      try(var.default_behavior.response_headers_policy_name, null) != null ? aws_cloudfront_response_headers_policy.managed[var.default_behavior.response_headers_policy_name].id : null
    )

    dynamic "forwarded_values" {
      for_each = try(var.default_behavior.use_forwarded_values, false) ? [1] : []
      content {
        query_string = try(var.default_behavior.forwarded_values.query_string, false)
        cookies {
          forward = try(var.default_behavior.forwarded_values.cookies_forward, "none")
        }
      }
    }

    dynamic "lambda_function_association" {
      for_each = try(var.default_behavior.lambda_function_associations, [])
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = try(lambda_function_association.value.include_body, false)
      }
    }

    dynamic "function_association" {
      for_each = try(var.default_behavior.function_associations, [])
      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy = try(ordered_cache_behavior.value.viewer_protocol_policy, "redirect-to-https")
      compress               = try(ordered_cache_behavior.value.compress, true)
      allowed_methods        = try(ordered_cache_behavior.value.allowed_methods, ["GET", "HEAD"])
      cached_methods         = try(ordered_cache_behavior.value.cached_methods, ["GET", "HEAD"])
      smooth_streaming       = try(ordered_cache_behavior.value.smooth_streaming, false)
      trusted_signers        = try(ordered_cache_behavior.value.trusted_signers, [])
      trusted_key_groups     = try(ordered_cache_behavior.value.trusted_key_groups, [])

      cache_policy_id = try(ordered_cache_behavior.value.cache_policy_id, null) != null ? ordered_cache_behavior.value.cache_policy_id : (
        try(ordered_cache_behavior.value.cache_policy_name, null) != null ? aws_cloudfront_cache_policy.managed[ordered_cache_behavior.value.cache_policy_name].id : null
      )
      origin_request_policy_id = try(ordered_cache_behavior.value.origin_request_policy_id, null) != null ? ordered_cache_behavior.value.origin_request_policy_id : (
        try(ordered_cache_behavior.value.origin_request_policy_name, null) != null ? aws_cloudfront_origin_request_policy.managed[ordered_cache_behavior.value.origin_request_policy_name].id : null
      )
      response_headers_policy_id = try(ordered_cache_behavior.value.response_headers_policy_id, null) != null ? ordered_cache_behavior.value.response_headers_policy_id : (
        try(ordered_cache_behavior.value.response_headers_policy_name, null) != null ? aws_cloudfront_response_headers_policy.managed[ordered_cache_behavior.value.response_headers_policy_name].id : null
      )

      dynamic "forwarded_values" {
        for_each = try(ordered_cache_behavior.value.use_forwarded_values, false) ? [1] : []
        content {
          query_string = try(ordered_cache_behavior.value.forwarded_values.query_string, false)
          cookies {
            forward = try(ordered_cache_behavior.value.forwarded_values.cookies_forward, "none")
          }
        }
      }

      dynamic "lambda_function_association" {
        for_each = try(ordered_cache_behavior.value.lambda_function_associations, [])
        content {
          event_type   = lambda_function_association.value.event_type
          lambda_arn   = lambda_function_association.value.lambda_arn
          include_body = try(lambda_function_association.value.include_body, false)
        }
      }

      dynamic "function_association" {
        for_each = try(ordered_cache_behavior.value.function_associations, [])
        content {
          event_type   = function_association.value.event_type
          function_arn = function_association.value.function_arn
        }
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction.type
      locations        = var.geo_restriction.locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = local.effective_certificate_arn == null
    acm_certificate_arn            = local.effective_certificate_arn
    ssl_support_method             = local.effective_certificate_arn == null ? null : try(var.viewer_certificate.ssl_support_method, "sni-only")
    minimum_protocol_version       = local.effective_certificate_arn == null ? null : try(var.viewer_certificate.minimum_protocol_version, "TLSv1.2_2021")
  }

  dynamic "logging_config" {
    for_each = var.logging == null ? [] : [var.logging]
    content {
      bucket          = logging_config.value.bucket_domain_name
      include_cookies = try(logging_config.value.include_cookies, false)
      prefix          = try(logging_config.value.prefix, "")
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = try(custom_error_response.value.response_code, null)
      response_page_path    = try(custom_error_response.value.response_page_path, null)
      error_caching_min_ttl = try(custom_error_response.value.error_caching_min_ttl, 300)
    }
  }

  tags = var.tags
}
