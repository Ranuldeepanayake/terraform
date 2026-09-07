resource "aws_security_group" "endpoint" {
  count = local.create_endpoint_security_group ? 1 : 0

  name_prefix = coalesce(var.security_group_name, "vpc-endpoint-${var.endpoint_name}-")
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      ResourceType = "SecurityGroup"
    }
  )
}

# Ingress rule.
resource "aws_vpc_security_group_ingress_rule" "endpoint" {
  for_each = local.create_endpoint_security_group ? {
    for index, rule in var.security_group_ingress_rules :
    index => rule
  } : {}

  security_group_id = aws_security_group.endpoint[0].id
  description       = try(each.value.description, null)

  ip_protocol = each.value.protocol
  from_port   = each.value.protocol == "-1" ? null : each.value.from_port
  to_port     = each.value.protocol == "-1" ? null : each.value.to_port

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
}

# Egress rule.
resource "aws_vpc_security_group_egress_rule" "endpoint" {
  for_each = local.create_endpoint_security_group ? {
    for index, rule in var.security_group_egress_rules :
    index => rule
  } : {}

  security_group_id = aws_security_group.endpoint[0].id
  description       = try(each.value.description, null)

  ip_protocol = each.value.protocol
  from_port   = each.value.protocol == "-1" ? null : each.value.from_port
  to_port     = each.value.protocol == "-1" ? null : each.value.to_port

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
}