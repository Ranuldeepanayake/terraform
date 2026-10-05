variable "name" {
  description = "Name used for CloudFront-related resources."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-_]{0,127}$", var.name))
    error_message = "name must contain only letters, numbers, hyphens, and underscores and be 1-128 characters long."
  }
}

variable "enabled" { type = bool, default = true }
variable "comment" { type = string, default = null }
variable "default_root_object" { type = string, default = null }
variable "aliases" { type = list(string), default = [] }
variable "price_class" { type = string, default = "PriceClass_All" }
variable "http_version" { type = string, default = "http2and3" }
variable "is_ipv6_enabled" { type = bool, default = true }
variable "retain_on_delete" { type = bool, default = false }
variable "wait_for_deployment" { type = bool, default = true }
variable "web_acl_arn" { type = string, default = null }
variable "tags" { type = map(string), default = {} }

variable "origins" {
  description = "Map of S3 or custom origins. S3 origins can use an automatically-created OAC."
  type = map(object({
    enabled                    = optional(bool, true)
    domain_name                = optional(string)
    s3_bucket_name             = optional(string)
    origin_path                = optional(string)
    create_oac                 = optional(bool, true)
    oac_name                   = optional(string)
    oac_description            = optional(string)
    oac_signing_behavior       = optional(string, "always")
    origin_access_control_id   = optional(string)
    origin_access_identity_path = optional(string)
    connection_attempts        = optional(number, 3)
    connection_timeout         = optional(number, 10)
    http_port                  = optional(number, 80)
    https_port                 = optional(number, 443)
    origin_protocol_policy     = optional(string, "https-only")
    origin_ssl_protocols       = optional(list(string), ["TLSv1.2"])
    origin_keepalive_timeout   = optional(number, 5)
    origin_read_timeout        = optional(number, 30)
    custom_headers = optional(list(object({
      name  = string
      value = string
    })), [])
  }))

  validation {
    condition = length(var.origins) > 0
    error_message = "At least one origin is required."
  }

  validation {
    condition = alltrue([
      for k, v in var.origins :
      try(v.s3_bucket_name, null) != null || try(v.domain_name, null) != null
    ])
    error_message = "Each enabled origin must specify either s3_bucket_name or domain_name."
  }
}

variable "default_behavior" {
  description = "Default cache behavior. Prefer cache/origin request policies over forwarded_values."
  type = object({
    target_origin_id             = string
    viewer_protocol_policy      = optional(string, "redirect-to-https")
    compress                    = optional(bool, true)
    allowed_methods             = optional(list(string), ["GET", "HEAD"])
    cached_methods              = optional(list(string), ["GET", "HEAD"])
    smooth_streaming            = optional(bool, false)
    trusted_signers             = optional(list(string), [])
    trusted_key_groups          = optional(list(string), [])
    cache_policy_id             = optional(string)
    cache_policy_name           = optional(string)
    origin_request_policy_id    = optional(string)
    origin_request_policy_name  = optional(string)
    response_headers_policy_id  = optional(string)
    response_headers_policy_name = optional(string)
    use_forwarded_values        = optional(bool, false)
    forwarded_values = optional(object({
      query_string    = optional(bool, false)
      cookies_forward = optional(string, "none")
    }), {})
    lambda_function_associations = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])
    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  })
}

variable "ordered_cache_behaviors" {
  description = "Ordered cache behaviors evaluated before the default behavior."
  type = list(object({
    path_pattern                = string
    target_origin_id            = string
    viewer_protocol_policy     = optional(string, "redirect-to-https")
    compress                   = optional(bool, true)
    allowed_methods            = optional(list(string), ["GET", "HEAD"])
    cached_methods             = optional(list(string), ["GET", "HEAD"])
    smooth_streaming           = optional(bool, false)
    trusted_signers            = optional(list(string), [])
    trusted_key_groups         = optional(list(string), [])
    cache_policy_id            = optional(string)
    cache_policy_name          = optional(string)
    origin_request_policy_id   = optional(string)
    origin_request_policy_name = optional(string)
    response_headers_policy_id = optional(string)
    response_headers_policy_name = optional(string)
    use_forwarded_values       = optional(bool, false)
    forwarded_values = optional(object({
      query_string    = optional(bool, false)
      cookies_forward = optional(string, "none")
    }), {})
    lambda_function_associations = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])
    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  }))

  validation {
    condition     = length(var.ordered_cache_behaviors) == length(distinct([for b in var.ordered_cache_behaviors : b.path_pattern]))
    error_message = "ordered_cache_behaviors must not contain duplicate path_pattern values."
  }
}

variable "viewer_certificate" {
  description = "ACM certificate configuration. The ACM certificate must be in us-east-1."
  type = object({
    acm_certificate_arn      = optional(string)
    ssl_support_method       = optional(string, "sni-only")
    minimum_protocol_version = optional(string, "TLSv1.2_2021")
  })
  default = {}
}

variable "geo_restriction" {
  type = object({
    type      = optional(string, "none")
    locations = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction.type)
    error_message = "geo_restriction.type must be none, whitelist, or blacklist."
  }
}

variable "logging" {
  description = "Standard CloudFront access logging. bucket_domain_name should normally be an S3 bucket regional domain name."
  type = object({
    bucket_domain_name = string
    include_cookies    = optional(bool, false)
    prefix             = optional(string, "")
  })
  default = null
}

variable "custom_error_responses" {
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number, 300)
  }))
  default = []
}

variable "create_cache_policies" { type = bool, default = true }
variable "create_origin_request_policies" { type = bool, default = true }
variable "create_response_headers_policies" { type = bool, default = true }

variable "cache_policies" {
  type = map(object({
    comment                       = optional(string)
    default_ttl                   = optional(number, 86400)
    max_ttl                       = optional(number, 31536000)
    min_ttl                       = optional(number, 0)
    enable_accept_encoding_brotli = optional(bool, true)
    enable_accept_encoding_gzip   = optional(bool, true)
    cookies = object({
      behavior = string
      items    = optional(list(string), [])
    })
    headers = object({
      behavior = string
      items    = optional(list(string), [])
    })
    query_strings = object({
      behavior = string
      items    = optional(list(string), [])
    })
  }))
  default = {}
}

variable "origin_request_policies" {
  type = map(object({
    comment = optional(string)
    cookies = object({
      behavior = string
      items    = optional(list(string), [])
    })
    headers = object({
      behavior = string
      items    = optional(list(string), [])
    })
    query_strings = object({
      behavior = string
      items    = optional(list(string), [])
    })
  }))
  default = {}
}

variable "response_headers_policies" {
  type = map(object({
    comment = optional(string)
    cors_config = optional(object({
      access_control_allow_credentials = optional(bool, false)
      access_control_allow_headers     = list(string)
      access_control_allow_methods     = list(string)
      access_control_allow_origins     = list(string)
      access_control_expose_headers    = optional(list(string), [])
      access_control_max_age_sec       = optional(number)
      origin_override                  = optional(bool, true)
    }))
    security_headers_config = optional(object({
      content_security_policy = optional(object({ value = string, override = optional(bool, true) }))
      content_type_options    = optional(object({ override = optional(bool, true) }))
      frame_options           = optional(object({ value = string, override = optional(bool, true) }))
      referrer_policy         = optional(object({ value = string, override = optional(bool, true) }))
      strict_transport_security = optional(object({
        access_control_max_age_sec = number
        include_subdomains         = optional(bool, true)
        override                   = optional(bool, true)
        preload                    = optional(bool, false)
      }))
      xss_protection = optional(object({
        mode_block = optional(bool, true)
        override   = optional(bool, true)
        protection = optional(bool, true)
        report_uri = optional(string)
      }))
    }))
    custom_headers = optional(list(object({
      header   = string
      override = optional(bool, true)
      value    = string
    })), [])
  }))
  default = {}
}
