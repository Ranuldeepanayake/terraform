terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }

  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-dev-eks-cluster"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# For Helm operations.
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name, "--region", var.aws_region]
    }
  }
}
