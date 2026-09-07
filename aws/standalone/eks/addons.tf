#EKS Add-ons: Essential managed components for cluster functionality.
#AWS manages updates and patches for these add-ons automatically.

#Extract OIDC provider URL for use in IRSA trust policies.
#Removes https:// prefix to match AWS OIDC provider naming convention.
locals {
  oidc_provider_url       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
  external_dns_policy_arn = coalesce(var.external_dns_policy_arn, "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.external_dns_policy_name}")
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = merge(
    var.tags,
    {
      resource-type = "iam-oidc-provider"
    }
  )
}

#VPC CNI (Container Network Interface) - handles pod networking within the VPC.
#Essential for pod-to-pod communication and service discovery.
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
      resource-type = "eks-addon"
    }
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }

  depends_on = [aws_eks_node_group.main]
}

#Data source to get the latest VPC CNI add-on version for the cluster version.
data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

#IAM role for VPC CNI service account. This allows the CNI plugin to manage VPC resources.
resource "aws_iam_role" "vpc_cni" {
  name_prefix = "${var.cluster_name}-vpc-cni-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-node"
            "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

#Attach CNI policy to VPC CNI role. Allows managing ENIs and security groups for pods.
resource "aws_iam_role_policy_attachment" "vpc_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni.name
}

#CoreDNS add-on - handles DNS resolution for services within the cluster.
#Essential for service discovery (e.g., accessing services by name).
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = data.aws_eks_addon_version.coredns.version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(
    var.tags,
    {
      resource-type = "eks-addon"
    }
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }

  depends_on = [aws_eks_node_group.main]
}

#Data source to get the latest CoreDNS add-on version for the cluster version.
data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

#kube-proxy add-on - handles service networking and load balancing.
#Maintains network rules on nodes to enable service communication.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(
    var.tags,
    {
      resource-type = "eks-addon"
    }
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }

  depends_on = [aws_eks_node_group.main]
}

#Data source to get the latest kube-proxy add-on version for the cluster version.
data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

#EBS CSI Driver add-on - enables dynamic provisioning of EBS volumes as PersistentVolumes.
#Uses IRSA so the controller can manage EBS volumes through its service account role.
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
      resource-type = "eks-addon"
    }
  )

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }

  depends_on = [aws_eks_node_group.main]
}

#Data source to get the latest EBS CSI Driver add-on version for the cluster version.
data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

#IAM role for EBS CSI Driver service account. Allows the driver to manage EBS volumes.
resource "aws_iam_role" "ebs_csi_driver" {
  name_prefix = "${var.cluster_name}-ebs-csi-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

#Attach EBS CSI Driver policy to enable volume provisioning.
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

#ExternalDNS add-on - manages Route53 DNS records for Kubernetes Services and Ingresses.
#Uses IRSA with the pre-created CustomPolicyEKSExternalDNS policy.
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
      resource-type = "eks-addon"
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

#Data source to get the latest ExternalDNS add-on version for the cluster version.
data "aws_eks_addon_version" "external_dns" {
  addon_name         = "external-dns"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

#IAM role for ExternalDNS service account. Allows ExternalDNS to manage Route53 records.
resource "aws_iam_role" "external_dns" {
  name_prefix = "${var.cluster_name}-external-dns-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url}:sub" = "system:serviceaccount:external-dns:external-dns"
            "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

#Attach the pre-created Route53 policy to enable ExternalDNS record management.
resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = local.external_dns_policy_arn
  role       = aws_iam_role.external_dns.name
}

#Data source to get AWS account ID for OIDC configuration.
data "aws_caller_identity" "current" {}

#Data source to support policy ARN construction across AWS partitions.
data "aws_partition" "current" {}
