terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55"
    }
  }

  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-subnet-1"
    }

  }
}

provider "aws" {
  region = local.aws_region
}