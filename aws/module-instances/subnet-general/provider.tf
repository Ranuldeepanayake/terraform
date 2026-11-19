terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-subnet-1"
    }

  }
}

provider "aws" {
  region = var.aws_region
}