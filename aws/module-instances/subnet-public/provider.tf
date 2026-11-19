terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-subnet-public"
    }
  }
}

provider "aws" {
  region = local.aws_region
}