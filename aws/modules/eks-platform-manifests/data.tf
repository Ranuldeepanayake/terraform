data "terraform_remote_state" "eks_platform" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = var.eks_platform_workspace_name
    }
  }
}