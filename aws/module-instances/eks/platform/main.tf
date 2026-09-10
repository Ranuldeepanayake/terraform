locals {
  aws_region     = "ap-southeast-1"
}

data "aws_eks_cluster" "this" {
  name = "eks-cluster"
}

# Can be removed after checking.
data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}

# Create a module for this. Use the standalone EKS for everything else for now.
module "eks_platform" {
  source = "../../../modules/eks-platform"

  eks_cluster_workspace_name = "aws-dev-eks-cluster"
  letsencrypt_email_address  = "ranuldeepanayake@outlook.com"

  route53_zones = {
    ranul_click = {
      dns_zone = "ranul.click"
      zone_id  = "Z0233745IB90EWVKK2K1"
    }
  }
}