terraform {
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