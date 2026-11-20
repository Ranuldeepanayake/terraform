locals {
  aws_region                 = "ap-southeast-1"
  eks_cluster_workspace_name = "aws-dev-eks-cluster"
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
module "eks_platform" {
  source = "../../../modules/eks-platform"

  eks_cluster_workspace_name = local.eks_cluster_workspace_name
  argocd_values              = file("${path.module}/argocd-values.yaml")

  addons = {
    metrics_server = {
      enabled = true
      # version = "..." # Omit to use the latest chart on installation.
    }
    nginx_ingress = {
      enabled = true
      # version = "..."
    }
    cert_manager = {
      enabled = true
      # version = "..."
    }
    argocd = {
      enabled = true
      # version = "..."
    }
    istio = {
      enabled = true
      # Set enabled = true and optionally specify an Istio chart version.
    }
  }
}