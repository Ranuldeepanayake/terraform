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
}