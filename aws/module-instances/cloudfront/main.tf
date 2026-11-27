# Locals for common variables.
locals {
  aws_region   = "ap-southeast-1"
  project_name = "s3-app"

  tags = {
    ProjectName      = local.project_name
    Environment      = "dev"
    ResourceCategory = "cloudfront"
    ManagedBy        = "terraform"
  }
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name                   = "s3-app"
  comment                = "CDN support for the s3-app"
  enabled                = true
  aliases                = ["cdn.s3-app.ranul.click"]
  route53_zone_id        = "Z0233745IB90EWVKK2K1"
  create_route53_records = true
  route53_alias_records  = false
  default_root_object    = "1782406968714-4332ebd5-ba93-40c4-8f15-e7af342b9cdf-s-l400.jpg"
  price_class            = "PriceClass_All"
  http_version           = "http2"
  is_ipv6_enabled        = true
  retain_on_delete       = false

  cloudwatch_log_export_enabled = true
  # cloudwatch_log_group_name                = "s3-app"
  # cloudwatch_log_delivery_source_name      = "CreatedByCloudFront-E1BDLID84MOL0G-ACCESS_LOGS"
  # cloudwatch_log_delivery_destination_name = "CF-E1BDLID84MOL0G-s3-app-1782548320848"
  cloudwatch_log_retention_in_days = 7

  origins = {
    "s3-app-frqsxgmb1j.s3.ap-southeast-1.amazonaws.com-mqv08rjtn69" = {
      s3_bucket_name       = "s3-app-frqsxgmb1j"
      origin_path          = ""
      create_oac           = true
      oac_name             = "oac-s3-app-frqsxgmb1j.s3.ap-southeast-1.amazonaws.co-mqv0b8xxkk0"
      oac_description      = "Created by CloudFront"
      oac_signing_behavior = "always"
      connection_attempts  = 3
      connection_timeout   = 5
    }
  }

  default_behavior = {
    target_origin_id       = "s3-app-frqsxgmb1j.s3.ap-southeast-1.amazonaws.com-mqv08rjtn69"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:104322896078:certificate/e180dd3c-6035-4b3b-848a-46264799da9f"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  geo_restriction = {
    type = "none"
  }

  tags = local.tags
}
