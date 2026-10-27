terraform {
  # Keep the Ubuntu caller in its own Terraform Cloud workspace.
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-ec2-ubuntu"
    }
  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}
