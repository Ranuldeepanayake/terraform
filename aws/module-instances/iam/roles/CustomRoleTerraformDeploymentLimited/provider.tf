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
      name = "aws-dev-iam-role-CustomRoleTerraformDeploymentLimited"
    }

  }
}

provider "aws" {
  region  = local.aws_region
  profile = "limited"

  assume_role {
    role_arn     = "arn:aws:iam::104322896078:role/CustomRoleSuperAdmin"
    session_name = "TerraformDeployment"
  }
}

