# Create the route table.
resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name         = var.route_table_name
      ResourceType = "route-table"
    }
  )
}

# Create routes for the route table.
resource "aws_route" "this" {
  for_each = var.routes

  route_table_id = aws_route_table.this.id

  # Destination.
  destination_cidr_block      = each.value.cidr_block
  destination_ipv6_cidr_block = each.value.ipv6_cidr_block
  destination_prefix_list_id  = each.value.prefix_list_id

  # Target (gateway).
  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  network_interface_id      = each.value.network_interface_id
  transit_gateway_id        = each.value.transit_gateway_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
  egress_only_gateway_id    = each.value.egress_only_gateway_id
  local_gateway_id          = each.value.local_gateway_id
  carrier_gateway_id        = each.value.carrier_gateway_id
  core_network_arn          = each.value.core_network_arn
}