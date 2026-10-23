terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.67.0"
    }
  }

  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-iam-role-CustomRoleGitHubWorkflows"
    }

  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}