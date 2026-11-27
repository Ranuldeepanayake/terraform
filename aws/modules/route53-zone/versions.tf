# Pin the module to supported Terraform and AWS provider major versions.
terraform {
  required_version = ">= 1.16.0, < 2.0.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "6.67.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}
