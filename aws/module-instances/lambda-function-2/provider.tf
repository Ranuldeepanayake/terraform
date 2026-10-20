terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-lambda-2"
    }

  }
}

provider "aws" {
  region  = local.aws_region
  profile = "limited"
}