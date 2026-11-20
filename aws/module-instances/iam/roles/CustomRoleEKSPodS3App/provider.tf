terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-iam-role-CustomRoleEKSPodS3App"
    }

  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}