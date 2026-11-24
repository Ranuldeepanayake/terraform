terraform {
  cloud {
    organization = "ranuldeepanayake"

    workspaces {
      name = "aws-dev-eks-cluster"
    }
  }
}

provider "aws" {
  region = local.aws_region
  profile = "limited"
}
