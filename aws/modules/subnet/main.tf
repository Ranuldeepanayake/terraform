resource "aws_subnet" "subnet" {
  for_each = var.subnets

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(
    {
      name = each.value.name
    },
    each.value.tags
  )
}

resource "aws_route_table" "route_table" {
  vpc_id = var.vpc_id
  tags = var.route_table_tags
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = var.default_route
  gateway_id             = var.internet_gateway_id
}

resource "aws_route_table_association" "rta" {
  for_each = aws_subnet.subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_table.id
}