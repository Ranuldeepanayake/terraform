terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-ec2-common"
    }
  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}
