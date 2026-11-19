terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-route-table-private"
    }
  }
}

provider "aws" {
  region = local.aws_region
  profile = "limited"
}