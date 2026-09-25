resource "aws_subnet" "subnet" {
  for_each = var.subnets

  vpc_id                          = var.vpc_id
  cidr_block                      = each.value.cidr_block
  ipv6_cidr_block                 = each.value.ipv6_cidr_block
  assign_ipv6_address_on_creation = each.value.assign_ipv6_address_on_creation
  availability_zone               = each.value.availability_zone
  map_public_ip_on_launch         = each.value.map_public_ip_on_launch

  tags = merge(
    var.tags,
    {
      ResourceType = "subnet"
    },
    each.value.tags
  )
}

resource "aws_route_table_association" "rta" {
  for_each = var.subnets

  subnet_id      = aws_subnet.subnet[each.key].id
  route_table_id = each.value.route_table_id
}