# Define cache policies managed by this module for use by distribution behaviors.
resource "aws_cloudfront_cache_policy" "managed" {
  for_each = var.create_cache_policies ? var.cache_policies : {}

  name        = each.key
  comment     = try(each.value.comment, null)
  default_ttl = try(each.value.default_ttl, 86400)
  max_ttl     = try(each.value.max_ttl, 31536000)
  min_ttl     = try(each.value.min_ttl, 0)

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = each.value.cookies.behavior
      dynamic "cookies" {
        for_each = each.value.cookies.behavior == "whitelist" ? [1] : []
        content {
          items = each.value.cookies.items
        }
      }
    }

    headers_config {
      header_behavior = each.value.headers.behavior
      dynamic "headers" {
        for_each = each.value.headers.behavior == "whitelist" ? [1] : []
        content {
          items = each.value.headers.items
        }
      }
    }

    query_strings_config {
      query_string_behavior = each.value.query_strings.behavior
      dynamic "query_strings" {
        for_each = each.value.query_strings.behavior == "whitelist" ? [1] : []
        content {
          items = each.value.query_strings.items
        }
      }
    }

    enable_accept_encoding_brotli = try(each.value.enable_accept_encoding_brotli, true)
    enable_accept_encoding_gzip   = try(each.value.enable_accept_encoding_gzip, true)
  }
}

# Define origin request policies for forwarding cookies, headers, and query strings.
resource "aws_cloudfront_origin_request_policy" "managed" {
  for_each = var.create_origin_request_policies ? var.origin_request_policies : {}

  name    = each.key
  comment = try(each.value.comment, null)

  cookies_config {
    cookie_behavior = each.value.cookies.behavior
    dynamic "cookies" {
      for_each = each.value.cookies.behavior == "whitelist" ? [1] : []
      content {
        items = each.value.cookies.items
      }
    }
  }

  headers_config {
    header_behavior = each.value.headers.behavior
    dynamic "headers" {
      for_each = each.value.headers.behavior == "whitelist" ? [1] : []
      content {
        items = each.value.headers.items
      }
    }
  }

  query_strings_config {
    query_string_behavior = each.value.query_strings.behavior
    dynamic "query_strings" {
      for_each = each.value.query_strings.behavior == "whitelist" ? [1] : []
      content {
        items = each.value.query_strings.items
      }
    }
  }
}
