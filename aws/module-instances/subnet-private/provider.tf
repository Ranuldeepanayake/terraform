terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-subnet-private"
    }
  }
}

provider "aws" {
  region = local.aws_region
}