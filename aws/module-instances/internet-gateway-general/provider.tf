terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-igw-1"
    }
  }
}

provider "aws" {
  region = local.aws_region
  profile = "super-user"
}