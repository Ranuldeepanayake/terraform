data "terraform_remote_state" "eks_cluster" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = var.eks_cluster_workspace_name
    }
  }
}