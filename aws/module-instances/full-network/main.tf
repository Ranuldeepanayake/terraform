module "vpc" {
  source = "../../modules/vpc"  
  name       = var.vpc_name
  cidr_block = var.vpc_cidr
  
  #Pass on all variables needed for the module.
}

module "internet_gateway" {
  source = "../../modules/internet-gateway"
  vpc_id = module.vpc.id

  #Pass on all variables needed for the module.
}

module "subnet" {
  source = "../../modules/subnet"

  vpc_id              = module.vpc.id
  internet_gateway_id = module.internet_gateway.id

  subnets = var.subnets
  destination_cidr_block = var.destination_cidr_block
  route_table_tags = merge(
    {
      type = "route-table"
    },
    var.route_table_tags
  )
}