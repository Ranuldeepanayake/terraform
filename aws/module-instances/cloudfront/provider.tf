terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-cloudfront-1"
    }
  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}

provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "super-user"
}
