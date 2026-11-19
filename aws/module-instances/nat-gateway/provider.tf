terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-nat-gateway"
    }
  }
}

provider "aws" {
  region = local.aws_region
  profile = "limited"
}