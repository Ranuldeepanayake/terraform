# Terraform and provider versions required by this module.
terraform {
  required_version = ">= 1.16.0, < 2.0.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "6.67.0"
      configuration_aliases = [aws.public]
    }
  }
}
