terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# ACM certificates for CloudFront MUST be created in us-east-1.
# This example assumes the certificate already exists.

module "cdn" {
  source = "../../"

  name    = "example-cdn"
  comment = "Production application CloudFront distribution"

  aliases = ["cdn.example.com"]

  viewer_certificate = {
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/REPLACE_ME"
  }

  origins = {
    app = {
      domain_name = "internal-alb-123456.ap-south-1.elb.amazonaws.com"
    }

    assets = {
      s3_bucket_name = "example-private-assets"
      create_oac     = true
    }
  }

  cache_policies = {
    static = {
      comment                       = "Static assets"
      default_ttl                   = 86400
      max_ttl                       = 31536000
      min_ttl                       = 0
      enable_accept_encoding_brotli = true
      enable_accept_encoding_gzip   = true
      cookies = {
        behavior = "none"
      }
      headers = {
        behavior = "none"
      }
      query_strings = {
        behavior = "none"
      }
    }

    dynamic = {
      comment = "Dynamic application content"
      default_ttl = 0
      max_ttl = 0
      min_ttl = 0
      cookies = {
        behavior = "all"
      }
      headers = {
        behavior = "whitelist"
        items    = ["Authorization", "Host", "Origin"]
      }
      query_strings = {
        behavior = "all"
      }
    }
  }

  origin_request_policies = {
    dynamic = {
      comment = "Forward application request attributes"
      cookies = {
        behavior = "all"
      }
      headers = {
        behavior = "whitelist"
        items    = ["Authorization", "Host", "Origin", "CloudFront-Viewer-Country"]
      }
      query_strings = {
        behavior = "all"
      }
    }
  }

  response_headers_policies = {
    security = {
      comment = "Baseline browser security headers"
      security_headers_config = {
        content_type_options = {}
        frame_options = {
          value = "DENY"
        }
        referrer_policy = {
          value = "strict-origin-when-cross-origin"
        }
        strict_transport_security = {
          access_control_max_age_sec = 31536000
          include_subdomains         = true
          preload                    = false
        }
      }
    }
  }

  default_behavior = {
    target_origin_id            = "app"
    cache_policy_name           = "dynamic"
    origin_request_policy_name  = "dynamic"
    response_headers_policy_name = "security"
    viewer_protocol_policy      = "redirect-to-https"
    allowed_methods             = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods               = ["GET", "HEAD", "OPTIONS"]
    compress                    = true
  }

  ordered_cache_behaviors = [
    {
      path_pattern                = "/assets/*"
      target_origin_id            = "assets"
      cache_policy_name           = "static"
      response_headers_policy_name = "security"
      viewer_protocol_policy      = "redirect-to-https"
    }
  ]

  geo_restriction = {
    type = "none"
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

output "cloudfront_domain_name" {
  value = module.cdn.domain_name
}

output "cloudfront_distribution_id" {
  value = module.cdn.distribution_id
}
