#EKS managed Node Group.
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  version         = var.cluster_version

  scaling_config {
    desired_size = var.desired_node_count
    max_size     = var.max_node_count
    min_size     = var.min_node_count
  }

  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  #Configure remote access for SSH. If ec2_ssh_key_name is provided, enable SSH with the specified key pair.
  #Otherwise, rely on AWS Systems Manager Session Manager for node access (recommended for security).
  dynamic "remote_access" {
    for_each = var.ec2_ssh_key_name != null ? [1] : []
    content {
      ec2_ssh_key = var.ec2_ssh_key_name
    }
  }

  tags = merge(
    var.tags,
    {
      resource-type  = "eks-node-group",
      resource-group = "${var.cluster_name}"
    }
  )

  #Ensure pre-requisite resources are created before creating the node group.
  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.main
  ]

  # Lifecycle to prevent unnecessary recreation
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }
}

# Note: The managed node group automatically creates the ASG with tags that cluster autoscaler can discover.
# Additional ASG tagging via aws_autoscaling_group_tag causes plan-time issues since ASG names are unknown
# until after the node group is created. Cluster autoscaler discovery works via the node group resource itself.
