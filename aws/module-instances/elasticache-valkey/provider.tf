terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-elasticache-1"
    }
  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}
