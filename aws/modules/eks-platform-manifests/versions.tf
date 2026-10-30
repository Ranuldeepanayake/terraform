terraform {
  required_version = ">= 1.16.0, < 2.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.67.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "3.4.0"
    }
  }
}