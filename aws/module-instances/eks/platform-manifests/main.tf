locals {
  aws_region                  = "ap-southeast-1"
  eks_cluster_workspace_name  = "aws-dev-eks-cluster"
  eks_platform_workspace_name = "aws-dev-eks-cluster-platform"
}

data "terraform_remote_state" "eks_cluster" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = local.eks_cluster_workspace_name
    }
  }
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.eks_cluster.outputs.cluster_id
}

# Create a module for this. Use the standalone EKS for everything else for now.
module "eks_platform_manifests" {
  source = "../../../modules/eks-platform-manifests"

  eks_platform_workspace_name = local.eks_platform_workspace_name
  letsencrypt_email_address   = "ranuldeepanayake@outlook.com"

  route53_zones = {
    ranul_click = {
      dns_zone = "ranul.click"
      zone_id  = "Z0233745IB90EWVKK2K1"
    }
  }
}