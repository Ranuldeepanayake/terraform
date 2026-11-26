variable "name" {
  description = "Name used for CloudFront-related resources."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-_]{0,127}$", var.name))
    error_message = "name must contain only letters, numbers, hyphens, and underscores and be 1-128 characters long."
  }
}

variable "enabled" {
  type    = bool
  default = true
}

variable "comment" {
  type    = string
  default = null
}

variable "default_root_object" {
  type    = string
  default = null
}

variable "aliases" {
  description = "Alternate domain names attached to the CloudFront distribution."
  type        = list(string)
  default     = []

  validation {
    condition = (
      (!var.create_acm_certificate && !var.create_route53_records) ||
      length(var.aliases) > 0
    )
    error_message = "At least one alias is required when creating an ACM certificate or Route 53 records."
  }

  validation {
    condition     = length(var.aliases) == length(distinct(var.aliases))
    error_message = "aliases must not contain duplicate domain names."
  }
}

variable "create_acm_certificate" {
  description = "Request and DNS-validate an ACM certificate in us-east-1 for all distribution aliases."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Public Route 53 hosted-zone ID used for certificate validation and optional alias records."
  type        = string
  default     = null

  validation {
    condition = (
      (!var.create_acm_certificate && !var.create_route53_records) ||
      (var.route53_zone_id != null && trimspace(var.route53_zone_id) != "")
    )
    error_message = "route53_zone_id is required when creating an ACM certificate or Route 53 records."
  }
}

variable "create_route53_records" {
  description = "Create Route 53 records pointing each alias to the CloudFront distribution."
  type        = bool
  default     = false
}

variable "route53_alias_records" {
  description = "Create A and AAAA alias records. Set false to manage a legacy CNAME instead."
  type        = bool
  default     = true
}

variable "route53_record_ttl" {
  description = "TTL for legacy CNAME records; ignored for Route 53 alias records."
  type        = number
  default     = 300

  validation {
    condition     = var.route53_record_ttl > 0
    error_message = "route53_record_ttl must be greater than zero."
  }
}

variable "price_class" {
  type    = string
  default = "PriceClass_All"
}

variable "http_version" {
  type    = string
  default = "http2and3"
}

variable "is_ipv6_enabled" {
  type    = bool
  default = true
}

variable "retain_on_delete" {
  type    = bool
  default = false
}

variable "wait_for_deployment" {
  type    = bool
  default = true
}

variable "web_acl_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "origins" {
  description = "Map of S3 or custom origins. S3 origins can use an automatically-created OAC."
  type = map(object({
    enabled                     = optional(bool, true)
    domain_name                 = optional(string)
    s3_bucket_name              = optional(string)
    origin_path                 = optional(string)
    create_oac                  = optional(bool, true)
    oac_name                    = optional(string)
    oac_description             = optional(string)
    oac_signing_behavior        = optional(string, "always")
    origin_access_control_id    = optional(string)
    origin_access_identity_path = optional(string)
    connection_attempts         = optional(number, 3)
    connection_timeout          = optional(number, 10)
    http_port                   = optional(number, 80)
    https_port                  = optional(number, 443)
    origin_protocol_policy      = optional(string, "https-only")
    origin_ssl_protocols        = optional(list(string), ["TLSv1.2"])
    origin_keepalive_timeout    = optional(number, 5)
    origin_read_timeout         = optional(number, 30)
    custom_headers = optional(list(object({
      name  = string
      value = string
    })), [])
  }))

  validation {
    condition     = length(var.origins) > 0
    error_message = "At least one origin is required."
  }

  validation {
    condition = alltrue([
      for k, v in var.origins :
      !try(v.enabled, true) || (
        try(v.s3_bucket_name, null) != null || try(v.domain_name, null) != null
      )
    ])
    error_message = "Each enabled origin must specify s3_bucket_name or domain_name."
  }
}

variable "default_behavior" {
  description = "Default cache behavior. Prefer cache/origin request policies over forwarded_values."
  type = object({
    target_origin_id             = string
    viewer_protocol_policy       = optional(string, "redirect-to-https")
    compress                     = optional(bool, true)
    allowed_methods              = optional(list(string), ["GET", "HEAD"])
    cached_methods               = optional(list(string), ["GET", "HEAD"])
    smooth_streaming             = optional(bool, false)
    trusted_signers              = optional(list(string), [])
    trusted_key_groups           = optional(list(string), [])
    cache_policy_id              = optional(string)
    cache_policy_name            = optional(string)
    origin_request_policy_id     = optional(string)
    origin_request_policy_name   = optional(string)
    response_headers_policy_id   = optional(string)
    response_headers_policy_name = optional(string)
    use_forwarded_values         = optional(bool, false)
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

  validation {
    condition = (
      (var.default_behavior.cache_policy_id != null || var.default_behavior.cache_policy_name != null)
      != var.default_behavior.use_forwarded_values
    )
    error_message = "default_behavior must specify exactly one cache policy ID/name or use_forwarded_values = true."
  }

  validation {
    condition = (
      !(var.default_behavior.cache_policy_id != null && var.default_behavior.cache_policy_name != null) &&
      !(var.default_behavior.origin_request_policy_id != null && var.default_behavior.origin_request_policy_name != null) &&
      !(var.default_behavior.response_headers_policy_id != null && var.default_behavior.response_headers_policy_name != null)
    )
    error_message = "Specify either an ID or a managed name for each default behavior policy, not both."
  }

  validation {
    condition = (
      (var.default_behavior.cache_policy_name == null ||
      (var.create_cache_policies && contains(keys(var.cache_policies), var.default_behavior.cache_policy_name))) &&
      (var.default_behavior.origin_request_policy_name == null ||
      (var.create_origin_request_policies && contains(keys(var.origin_request_policies), var.default_behavior.origin_request_policy_name))) &&
      (var.default_behavior.response_headers_policy_name == null ||
      (var.create_response_headers_policies && contains(keys(var.response_headers_policies), var.default_behavior.response_headers_policy_name)))
    )
    error_message = "Default behavior policy names must refer to policies enabled and declared in this module; use policy IDs for existing policies."
  }

  validation {
    condition = (
      contains(keys(var.origins), var.default_behavior.target_origin_id) &&
      try(var.origins[var.default_behavior.target_origin_id].enabled, true)
    )
    error_message = "default_behavior.target_origin_id must refer to an enabled origin."
  }
}

variable "ordered_cache_behaviors" {
  description = "Ordered cache behaviors evaluated before the default behavior."
  type = list(object({
    path_pattern                 = string
    target_origin_id             = string
    viewer_protocol_policy       = optional(string, "redirect-to-https")
    compress                     = optional(bool, true)
    allowed_methods              = optional(list(string), ["GET", "HEAD"])
    cached_methods               = optional(list(string), ["GET", "HEAD"])
    smooth_streaming             = optional(bool, false)
    trusted_signers              = optional(list(string), [])
    trusted_key_groups           = optional(list(string), [])
    cache_policy_id              = optional(string)
    cache_policy_name            = optional(string)
    origin_request_policy_id     = optional(string)
    origin_request_policy_name   = optional(string)
    response_headers_policy_id   = optional(string)
    response_headers_policy_name = optional(string)
    use_forwarded_values         = optional(bool, false)
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
  default = []

  validation {
    condition     = length(var.ordered_cache_behaviors) == length(distinct([for b in var.ordered_cache_behaviors : b.path_pattern]))
    error_message = "ordered_cache_behaviors must not contain duplicate path_pattern values."
  }

  validation {
    condition = alltrue([
      for b in var.ordered_cache_behaviors :
      ((b.cache_policy_id != null || b.cache_policy_name != null) != b.use_forwarded_values)
    ])
    error_message = "Each ordered behavior must specify exactly one cache policy ID/name or use_forwarded_values = true."
  }

  validation {
    condition = alltrue([
      for b in var.ordered_cache_behaviors :
      !(b.cache_policy_id != null && b.cache_policy_name != null) &&
      !(b.origin_request_policy_id != null && b.origin_request_policy_name != null) &&
      !(b.response_headers_policy_id != null && b.response_headers_policy_name != null)
    ])
    error_message = "Specify either an ID or a managed name for each ordered behavior policy, not both."
  }

  validation {
    condition = alltrue([
      for b in var.ordered_cache_behaviors :
      (b.cache_policy_name == null ||
      (var.create_cache_policies && contains(keys(var.cache_policies), b.cache_policy_name))) &&
      (b.origin_request_policy_name == null ||
      (var.create_origin_request_policies && contains(keys(var.origin_request_policies), b.origin_request_policy_name))) &&
      (b.response_headers_policy_name == null ||
      (var.create_response_headers_policies && contains(keys(var.response_headers_policies), b.response_headers_policy_name)))
    ])
    error_message = "Ordered behavior policy names must refer to policies enabled and declared in this module; use policy IDs for existing policies."
  }

  validation {
    condition = alltrue([
      for b in var.ordered_cache_behaviors :
      contains(keys(var.origins), b.target_origin_id) &&
      try(var.origins[b.target_origin_id].enabled, true)
    ])
    error_message = "Each ordered behavior target_origin_id must refer to an enabled origin."
  }
}

variable "viewer_certificate" {
  description = "Existing ACM certificate configuration. Use create_acm_certificate to provision one in us-east-1."
  type = object({
    acm_certificate_arn      = optional(string)
    ssl_support_method       = optional(string, "sni-only")
    minimum_protocol_version = optional(string, "TLSv1.2_2021")
  })
  default = {}

  validation {
    condition = (
      !var.create_acm_certificate ||
      var.viewer_certificate.acm_certificate_arn == null
    )
    error_message = "Do not set viewer_certificate.acm_certificate_arn when create_acm_certificate is enabled."
  }
}

variable "route53_validation_wait" {
  description = "Maximum time to wait for DNS validation of a newly requested ACM certificate."
  type        = string
  default     = "60m"
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

variable "create_cache_policies" {
  type    = bool
  default = true
}

variable "create_origin_request_policies" {
  type    = bool
  default = true
}

variable "create_response_headers_policies" {
  type    = bool
  default = true
}

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
