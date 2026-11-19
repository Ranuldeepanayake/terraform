terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-api-gw-2"
    }
  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}
