terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55"
    }
  }

  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-vpc-1"
    }

  }
}

provider "aws" {
  region = var.aws_region
}