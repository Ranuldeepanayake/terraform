#Security group for the EKS cluster control plane.
resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      resource-type = "security-group"
    }
  )
}

#Ingress rule: Allow worker nodes to communicate with cluster API.
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
  description              = "Allow EKS nodes to communicate with cluster API"
}

#Ingress rule: Allow HTTPS from cluster security group itself.
resource "aws_security_group_rule" "cluster_ingress_self" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  self              = true
  description       = "Allow cluster to communicate with itself"
}

#Egress rule: Allow all outbound traffic.
resource "aws_security_group_rule" "cluster_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound traffic"
}

#Security group for the EKS worker nodes.
resource "aws_security_group" "nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      resource-type = "security-group"
    }
  )
}

#Ingress rule: Allow nodes to communicate with each other.
resource "aws_security_group_rule" "nodes_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.nodes.id
  self              = true
  description       = "Allow nodes to communicate with each other"
}

#Ingress rule: Allow UDP traffic between nodes.
resource "aws_security_group_rule" "nodes_ingress_self_udp" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "udp"
  security_group_id = aws_security_group.nodes.id
  self              = true
  description       = "Allow UDP traffic between nodes"
}

#Ingress rule: Allow cluster control plane to communicate with nodes.
resource "aws_security_group_rule" "nodes_ingress_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  description              = "Allow cluster control plane to communicate with nodes"
}

#Ingress rule: Allow cluster to reach kubelet API.
resource "aws_security_group_rule" "nodes_ingress_cluster_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  description              = "Allow cluster control plane to reach kubelet API"
}

#Ingress rule: Allow HTTP from internet for nginx ingress and services.
resource "aws_security_group_rule" "nodes_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nodes.id
  description       = "Allow HTTP from internet to nginx ingress controller"
}

#Ingress rule: Allow HTTPS from internet for nginx ingress and services.
resource "aws_security_group_rule" "nodes_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nodes.id
  description       = "Allow HTTPS from internet to nginx ingress controller"
}

#Ingress rule: Allow SSH from the node security group itself (for EC2 key pair access).
#This enables SSH access when an EC2 key pair is configured in the node group.
resource "aws_security_group_rule" "nodes_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.nodes.id
  self              = true
  description       = "Allow SSH between nodes and for EC2 key pair access"
}

#Egress rule: Allow all outbound traffic.
resource "aws_security_group_rule" "nodes_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nodes.id
  description       = "Allow all outbound traffic"
}
