# Configure a dedicated Terraform Cloud workspace for the Route 53 zone caller.
terraform {
  cloud {
    organization = "ranuldeepanayake"

    workspaces {
      name = "aws-dev-route53-zone-ranul-click"
    }
  }
}

# Configure AWS credentials and the default region used for this hosted zone.
provider "aws" {
  region  = local.aws_region
  profile = "super-user"
}

# Route 53 query logs can only target a CloudWatch Logs group in us-east-1.
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "super-user"
}
