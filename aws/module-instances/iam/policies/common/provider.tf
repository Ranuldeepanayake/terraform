terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-iam-policies-common"
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