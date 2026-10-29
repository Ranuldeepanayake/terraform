terraform {
  required_version = ">= 1.16.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.67.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
    }
  }
}
