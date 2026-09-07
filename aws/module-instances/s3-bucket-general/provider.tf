terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  cloud {
    organization = "ranuldeepanayake"

    workspaces {
      name = "s3-bucket-general"
    }
  }
}

provider "aws" {
  region = var.aws_region
}