# AWS EKS ddd-ons: Essential managed components for cluster functionality.
# AWS manages updates and patches for these add-ons automatically.

# Data source to get the latest VPC CNI add-on version for the cluster version.
data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

# VPC CNI (Container Network Interface) - handles pod networking within the VPC.
# Essential for pod-to-pod communication and service discovery.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = data.aws_eks_addon_version.vpc_cni.version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.vpc_cni.arn

  tags = merge(
    var.tags,
    {
      ResourceType = "eks-addon"
    }
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }

  depends_on = [aws_eks_node_group.main]
}

# Data source to get the latest CoreDNS add-on version for the cluster version.
data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

# CoreDNS add-on - handles DNS resolution for services within the cluster.
# Essential for service discovery (e.g., accessing services by name).
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = data.aws_eks_addon_version.coredns.version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(
    var.tags,
    {
      ResourceType = "eks-addon"
    }
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }

  depends_on = [aws_eks_node_group.main]
}

# Data source to get the latest kube-proxy add-on version for the cluster version.
data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

# kube-proxy add-on - handles service networking and load balancing.
# Maintains network rules on nodes to enable service communication.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(
    var.tags,
    {
      ResourceType = "eks-addon"
    }
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }

  depends_on = [aws_eks_node_group.main]
}

# Data source to get the latest EBS CSI Driver add-on version for the cluster version.
data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

# EBS CSI Driver add-on - enables dynamic provisioning of EBS volumes as PersistentVolumes.
# Uses IRSA so the controller can manage EBS volumes through its service account role.
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = data.aws_eks_addon_version.ebs_csi.version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn

  tags = merge(
    var.tags,
    {
      ResourceType = "eks-addon"
    }
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }

  depends_on = [aws_eks_node_group.main]
}

# Data source to get the latest ExternalDNS add-on version for the cluster version.
data "aws_eks_addon_version" "external_dns" {
  addon_name         = "external-dns"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

# ExternalDNS to manage Route53 DNS records for Kubernetes ingresses and load balancers.
# Uses IRSA with the pre-created CustomPolicyEKSExternalDNS policy.
resource "aws_eks_addon" "external_dns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "external-dns"
  addon_version               = data.aws_eks_addon_version.external_dns.version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.external_dns.arn

  tags = merge(
    var.tags,
    {
      ResourceType = "eks-addon"
    }
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.external_dns
  ]
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [
    aws_eks_node_group.main
  ]
}

# Data source to support policy ARN construction across AWS partitions.
data "aws_caller_identity" "current" {}

# Data source to support policy ARN construction across AWS partitions.
data "aws_partition" "current" {}
