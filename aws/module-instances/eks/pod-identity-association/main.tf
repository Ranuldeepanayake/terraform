locals {
  aws_region = "ap-southeast-1"

  tags = {
    Environment      = "dev"
    ManagedBy        = "terraform"
    ResourceCategory = "eks-pod-identity"
  }
}

data "terraform_remote_state" "eks" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = "aws-dev-eks-cluster"
    }
  }
}

module "pod_identity_association" {
  source = "../../../modules/eks-pod-identity-association"

  cluster_name    = data.terraform_remote_state.eks.outputs.cluster_id
  namespace       = "s3-app-dev"
  service_account = "sa-s3-app-dev"
  role_arn        = "arn:aws:iam::104322896078:role/CustomRoleEKSPodS3App"

  disable_session_tags = false
  target_role_arn      = null
  tags                 = local.tags
}
