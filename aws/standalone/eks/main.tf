#CloudWatch Log Group for EKS cluster logging.
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(
    var.tags,
    {
      resource-type = "cloudwatch-log-group"
    }
  )
}

#EKS cluster.
# Note: Other useful configurations that could be added:
# - encryption_config: Enable etcd encryption with AWS KMS
# - cluster_ip_family: Set to "ipv6" for dual-stack networking
# - outpost_config: For on-premises Outpost deployments
resource "aws_eks_cluster" "main" {
  name                      = var.cluster_name
  role_arn                  = aws_iam_role.cluster.arn
  version                   = var.cluster_version
  enabled_cluster_log_types = var.enable_cluster_logging

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
  }

  #Configure Kubernetes networking. Specifies CIDR blocks for service IPs and pod networking.
  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  #Configure Kubernetes version support policy for the cluster management plane.
  upgrade_policy {
    support_type = var.cluster_upgrade_support_type
  }

  #Configure access for the cluster. The access_config block allows you to specify how the cluster can be accessed.
  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  #Ensure pre-requisite resources are created before creating the EKS cluster.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.cluster
  ]

  tags = merge(
    var.tags,
    {
      resource-type = "eks-cluster"
    }
  )
}

#Output kubeconfig.
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig-${var.cluster_name}.yaml"
  content = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_name        = aws_eks_cluster.main.name
    endpoint            = aws_eks_cluster.main.endpoint
    cluster_auth_base64 = aws_eks_cluster.main.certificate_authority[0].data
    region              = var.aws_region
  })
}
