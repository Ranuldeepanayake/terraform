terraform {
  required_version = "~> 1.16.0"

  cloud {
    organization = "ranuldeepanayake"

    workspaces {
      name = "s3-bucket-general"
    }
  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}