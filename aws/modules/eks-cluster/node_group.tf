# Each managed node group has independent scaling, compute, networking, and
# scheduling settings. All groups share the module-owned worker IAM role.
resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.value.node_group_name
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = coalesce(each.value.subnet_ids, aws_subnet.private[*].id)
  capacity_type   = each.value.capacity_type

  version = (
    each.value.launch_template != null && each.value.launch_template.custom_ami
    ? null
    : coalesce(each.value.kubernetes_version, var.cluster_version)
  )

  release_version = (
    each.value.launch_template != null && each.value.launch_template.custom_ami
    ? null
    : each.value.release_version
  )
  ami_type = (
    each.value.launch_template != null && each.value.launch_template.custom_ami
    ? null
    : each.value.ami_type
  )
  force_update_version = each.value.force_update_version

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  instance_types = length(each.value.instance_types) > 0 ? each.value.instance_types : null
  disk_size      = each.value.launch_template == null ? coalesce(each.value.disk_size, 20) : null

  dynamic "launch_template" {
    for_each = each.value.launch_template == null ? [] : [each.value.launch_template]

    content {
      id      = launch_template.value.id
      name    = launch_template.value.name
      version = coalesce(launch_template.value.version, "$Default")
    }
  }

  dynamic "remote_access" {
    for_each = each.value.remote_access == null ? [] : [each.value.remote_access]

    content {
      ec2_ssh_key               = remote_access.value.ec2_ssh_key
      source_security_group_ids = length(remote_access.value.source_security_group_ids) > 0 ? remote_access.value.source_security_group_ids : null
    }
  }

  dynamic "update_config" {
    for_each = each.value.update_config == null ? [] : [each.value.update_config]

    content {
      max_unavailable            = update_config.value.max_unavailable
      max_unavailable_percentage = update_config.value.max_unavailable_percentage
    }
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      ResourceType = "eks-node-group"
      NodeGroupKey = each.key
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.main
  ]

  # Cluster autoscaling owns desired capacity after initial node group creation.
  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }
}

# Add discovery tags to the underlying Auto Scaling group for each managed
# node group. Tags on the EKS node group itself are not automatically
# propagated to the Auto Scaling group that Cluster Autoscaler discovers.
resource "aws_autoscaling_group_tag" "cluster_autoscaler_enabled" {
  for_each = var.enable_cluster_autoscaling ? var.node_groups : {}

  autoscaling_group_name = aws_eks_node_group.this[each.key].resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler_cluster" {
  for_each = var.enable_cluster_autoscaling ? var.node_groups : {}

  autoscaling_group_name = aws_eks_node_group.this[each.key].resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }
}
