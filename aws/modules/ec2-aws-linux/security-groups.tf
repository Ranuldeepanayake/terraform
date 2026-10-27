# Create a security group when the caller does not supply existing groups.
resource "aws_security_group" "this" {
  count       = var.create_security_group ? 1 : 0
  name        = "${var.instance_name}-${local.random_suffix}"
  description = var.security_group_description
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      prefix_list_ids  = ingress.value.prefix_list_ids
      security_groups  = ingress.value.security_groups
    }
  }

  dynamic "egress" {
    for_each = var.security_group_egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      prefix_list_ids  = egress.value.prefix_list_ids
      security_groups  = egress.value.security_groups
    }
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "security-group"
      Name         = "${var.instance_name}-${local.random_suffix}"
    }
  )
}