terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-lambda-3"
    }

  }
}

provider "aws" {
  region  = local.aws_region
  profile = "limited"
}