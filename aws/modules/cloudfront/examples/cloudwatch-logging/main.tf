terraform {
  required_version = ">= 1.16.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.67.0"
    }
  }
}

provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "testing"
  secret_key                  = "testing"
  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "aws" {
  alias                       = "us_east_1"
  region                      = "us-east-1"
  access_key                  = "testing"
  secret_key                  = "testing"
  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

module "cloudfront" {
  source = "../.."

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name    = "example-cdn"
  comment = "CloudFront logging example"

  origins = {
    app = {
      domain_name = "origin.example.com"
    }
  }

  default_behavior = {
    target_origin_id = "app"
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  cloudwatch_log_export_enabled    = true
  cloudwatch_log_group_name        = null
  cloudwatch_log_retention_in_days = 7

  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

output "cloudwatch_log_group_name" {
  value = module.cloudfront.cloudwatch_log_group_name
}

output "cloudwatch_log_delivery_id" {
  value = module.cloudfront.cloudwatch_log_delivery_id
}
