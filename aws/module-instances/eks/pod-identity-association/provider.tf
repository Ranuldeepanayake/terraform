terraform {
  cloud {
    organization = "ranuldeepanayake"

    workspaces {
      name = "aws-dev-eks-pod-identity-association"
    }
  }
}

provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}
