terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-iam-role-CustomRoleSuperAdmin"
    }

  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}