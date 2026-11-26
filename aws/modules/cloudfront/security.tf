# Define response-header policies for browser security headers, CORS, and custom headers.
resource "aws_cloudfront_response_headers_policy" "managed" {
  for_each = var.create_response_headers_policies ? var.response_headers_policies : {}

  name    = each.key
  comment = try(each.value.comment, null)

  dynamic "cors_config" {
    for_each = try(each.value.cors_config, null) == null ? [] : [each.value.cors_config]
    content {
      access_control_allow_credentials = try(cors_config.value.access_control_allow_credentials, false)
      access_control_allow_headers {
        items = cors_config.value.access_control_allow_headers
      }
      access_control_allow_methods {
        items = cors_config.value.access_control_allow_methods
      }
      access_control_allow_origins {
        items = cors_config.value.access_control_allow_origins
      }
      access_control_expose_headers {
        items = try(cors_config.value.access_control_expose_headers, [])
      }
      access_control_max_age_sec = try(cors_config.value.access_control_max_age_sec, null)
      origin_override            = try(cors_config.value.origin_override, true)
    }
  }

  dynamic "security_headers_config" {
    for_each = try(each.value.security_headers_config, null) == null ? [] : [each.value.security_headers_config]
    content {
      dynamic "content_security_policy" {
        for_each = try(security_headers_config.value.content_security_policy, null) == null ? [] : [security_headers_config.value.content_security_policy]
        content {
          content_security_policy = content_security_policy.value.value
          override                = try(content_security_policy.value.override, true)
        }
      }
      dynamic "content_type_options" {
        for_each = try(security_headers_config.value.content_type_options, null) == null ? [] : [1]
        content {
          override = try(security_headers_config.value.content_type_options.override, true)
        }
      }
      dynamic "frame_options" {
        for_each = try(security_headers_config.value.frame_options, null) == null ? [] : [security_headers_config.value.frame_options]
        content {
          frame_option = frame_options.value.value
          override     = try(frame_options.value.override, true)
        }
      }
      dynamic "referrer_policy" {
        for_each = try(security_headers_config.value.referrer_policy, null) == null ? [] : [security_headers_config.value.referrer_policy]
        content {
          referrer_policy = referrer_policy.value.value
          override        = try(referrer_policy.value.override, true)
        }
      }
      dynamic "strict_transport_security" {
        for_each = try(security_headers_config.value.strict_transport_security, null) == null ? [] : [security_headers_config.value.strict_transport_security]
        content {
          access_control_max_age_sec = strict_transport_security.value.access_control_max_age_sec
          include_subdomains         = try(strict_transport_security.value.include_subdomains, true)
          override                   = try(strict_transport_security.value.override, true)
          preload                    = try(strict_transport_security.value.preload, false)
        }
      }
      dynamic "xss_protection" {
        for_each = try(security_headers_config.value.xss_protection, null) == null ? [] : [security_headers_config.value.xss_protection]
        content {
          mode_block = try(xss_protection.value.mode_block, true)
          override   = try(xss_protection.value.override, true)
          protection = try(xss_protection.value.protection, true)
          report_uri = try(xss_protection.value.report_uri, null)
        }
      }
    }
  }

  dynamic "custom_headers_config" {
    for_each = try(each.value.custom_headers, [])
    content {
      items {
        header   = custom_headers_config.value.header
        override = try(custom_headers_config.value.override, true)
        value    = custom_headers_config.value.value
      }
    }
  }
}
