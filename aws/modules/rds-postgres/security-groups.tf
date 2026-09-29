# -----------------------------------------------------------------------------
# Security group
#
# This resource is only created when create_security_group = true.
# -----------------------------------------------------------------------------

# Creates the optional security group for the DB instance.
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name_prefix = var.security_group_name != null ? var.security_group_name : "${var.identifier}"
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name         = var.security_group_name != null ? var.security_group_name : "${var.identifier}-sg"
      ResourceType = "security-group"
    }
  )
}

# Creates caller-specified ingress rules for the security group.
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.create_security_group ? {
    for index, rule in var.security_group_ingress_rules :
    index => rule
  } : {}

  security_group_id = aws_security_group.this[0].id

  description = each.value.description

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.ip_protocol

  cidr_ipv4 = each.value.cidr_ipv4
  cidr_ipv6 = each.value.cidr_ipv6

  referenced_security_group_id = each.value.referenced_security_group_id
}

# Creates caller-specified egress rules for the security group.
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = var.create_security_group ? {
    for index, rule in var.security_group_egress_rules :
    index => rule
  } : {}

  security_group_id = aws_security_group.this[0].id

  description = each.value.description

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.ip_protocol

  cidr_ipv4 = each.value.cidr_ipv4
  cidr_ipv6 = each.value.cidr_ipv6

  referenced_security_group_id = each.value.referenced_security_group_id
}