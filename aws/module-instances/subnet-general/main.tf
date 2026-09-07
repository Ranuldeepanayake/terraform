module "subnet" {
  source = "../../modules/subnet"

  vpc_id              = var.vpc_id
  internet_gateway_id = var.internet_gateway_id

  subnets       = var.subnets
  default_route = var.default_route
  route_table_tags = merge(
    {
      type = "route-table"
    },
    var.route_table_tags
  )
}