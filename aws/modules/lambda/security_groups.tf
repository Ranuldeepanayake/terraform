# Create dedicated security group for the Lambda function if specified.
resource "aws_security_group" "lambda" {
  count = local.create_lambda_security_group ? 1 : 0

  #Use the security group name provided by the user.
  name        = var.security_group_name
  description = coalesce(var.security_group_description, "Security group for Lambda function ${var.function_name}")
  vpc_id      = data.aws_subnet.lambda[0].vpc_id

  tags = merge(
    var.tags,
    {
      ResourceType = "security-group"
    }
  )
}

# Create ingress rules for the Lambda security group if specified.
resource "aws_vpc_security_group_ingress_rule" "lambda" {
  for_each = local.create_lambda_security_group ? var.security_group_ingress_rules : {}

  security_group_id = aws_security_group.lambda[0].id
  description       = try(each.value.description, null)
  from_port         = each.value.protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = try(each.value.cidr_ipv4, null)
  cidr_ipv6         = try(each.value.cidr_ipv6, null)

  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
}

# Create egress rules for the Lambda security group if specified.
resource "aws_vpc_security_group_egress_rule" "lambda" {
  for_each = local.create_lambda_security_group ? var.security_group_egress_rules : {}

  security_group_id = aws_security_group.lambda[0].id
  description       = try(each.value.description, null)
  from_port         = each.value.protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = try(each.value.cidr_ipv4, null)
  cidr_ipv6         = try(each.value.cidr_ipv6, null)

  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
}