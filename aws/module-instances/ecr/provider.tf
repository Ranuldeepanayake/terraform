terraform {
  cloud {
    organization = "ranuldeepanayake"

    workspaces {
      name = "aws-dev-ecr"
    }
  }
}

# Private ECR repositories are created in the application region.
provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}

# AWS ECR Public is hosted only in us-east-1.
provider "aws" {
  alias   = "public"
  region  = "us-east-1"
  profile = "super-user"
}
