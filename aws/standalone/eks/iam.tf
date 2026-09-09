#IAM role for EKS cluster control plane.
resource "aws_iam_role" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      ResourceType = "iam-role"
    }
  )
}

#Attach required EKS cluster policy to the cluster role. This policy allows the EKS control plane to manage AWS resources on behalf of the cluster.
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

#Attach VPC resource controller policy for security groups for pods to the cluster role. This allows the EKS control plane to manage VPC resources for pods.
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

#IAM role for EKS worker nodes.
resource "aws_iam_role" "nodes" {
  name_prefix = "${var.cluster_name}-nodes-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      ResourceType = "iam-role"
    }
  )
}

#Attach EKS worker node policy to the node role. These policies allow the worker nodes to join the EKS cluster.
resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

#Attach instance profile to worker nodes. This allows the worker nodes to assume the IAM role and access AWS resources.
resource "aws_iam_instance_profile" "nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  role        = aws_iam_role.nodes.name
}

#EKS access entry for cluster admin user. This configures RBAC access at the cluster level.
#Only created if bootstrap_cluster_creator_admin_permissions is false. Otherwise, the cluster creator gets admin automatically.
resource "aws_eks_access_entry" "admin_user" {
  count             = var.bootstrap_cluster_creator_admin_permissions ? 0 : 1
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = var.cluster_admin_user_arn
  kubernetes_groups = []
  type              = "STANDARD"
}

#Associate cluster admin policy to the access entry. This grants the specified IAM user full administrative access to the EKS cluster.
#Only created if bootstrap_cluster_creator_admin_permissions is false. Otherwise, the cluster creator gets admin automatically.
resource "aws_eks_access_policy_association" "admin_user" {
  count         = var.bootstrap_cluster_creator_admin_permissions ? 0 : 1
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.cluster_admin_user_arn

  access_scope {
    type = "cluster"
  }
}

#Attach CNI plugin policy to manage networking resources of the worker nodes to the node role. This allows the worker nodes to manage networking resources for pods.
resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

#Attach ECR policy to pull container images from the worker nodes to the worker role. This allows the worker nodes to pull container images from Amazon ECR.
resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

#Attach SSM policy to allow worker nodes to communicate with AWS Systems Manager for management and monitoring to the worker node role. 
#This allows the worker nodes to communicate with AWS Systems Manager for management and monitoring.
resource "aws_iam_role_policy_attachment" "nodes_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nodes.name
}

#Attach EBS CSI driver policy to enable dynamic provisioning of EBS volumes as PersistentVolumes.
#This allows the EBS CSI driver to manage EBS volumes for pods requesting storage.
resource "aws_iam_role_policy_attachment" "nodes_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.nodes.name
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

  tags = merge(
    var.tags,
    {
      ResourceType = "iam-role-policy-attachment"
    }
  )
}

#Attach the pre-created Route53 policy to enable ExternalDNS record management.
resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = local.external_dns_policy_arn
  role       = aws_iam_role.external_dns.name
}

# IAM policy for cert-manager to manage Route53 DNS records for ACME challenges.
data "aws_iam_policy_document" "cert_manager_route53" {
  statement {
    sid    = "GetRoute53Change"
    effect = "Allow"

    actions = [
      "route53:GetChange"
    ]

    resources = [
      "arn:aws:route53:::change/*"
    ]
  }

  statement {
    sid    = "ChangeAcmeDnsRecords"
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]

    resources = [
      "arn:aws:route53:::hostedzone/*"
    ]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values   = ["TXT"]
    }
  }
}

# Assign the cert-manager Route53 policy document to the IAM policy resource.
resource "aws_iam_policy" "cert_manager_route53" {
  name_prefix = "CustomPolicyCertManagerRoute53-${var.cluster_name}-"
  policy      = data.aws_iam_policy_document.cert_manager_route53.json
}

# IAM role for cert-manager to assume for managing Route53 DNS records for ACME challenges.
data "aws_iam_policy_document" "cert_manager_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type = "Service"

      identifiers = [
        "pods.eks.amazonaws.com"
      ]
    }
  }
}

# Assign the cert-manager Route53 role document to the IAM role resource.
resource "aws_iam_role" "cert_manager" {
  name_prefix        = "CustomRoleCertManagerRoute53-${var.cluster_name}-"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume_role.json
}

# Assign the cert-manager Route53 policy to the cert-manager IAM role.
resource "aws_iam_role_policy_attachment" "cert_manager_route53" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager_route53.arn
}

# Create the pod identity association to allow cert-manager pods to assume the IAM role for managing 
# Route53 DNS records for ACME challenges.
resource "aws_eks_pod_identity_association" "cert_manager" {
  cluster_name = aws_eks_cluster.main.name

  namespace       = var.cert_manager_namespace
  service_account = var.cert_manager_service_account

  role_arn = aws_iam_role.cert_manager.arn

  depends_on = [
    aws_iam_role_policy_attachment.cert_manager_route53,
    helm_release.cert_manager
  ]
}