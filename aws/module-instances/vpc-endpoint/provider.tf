terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-vpc-endpoint-1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = "super-user"
}