# Locals for common variables.
locals {
  aws_region = "ap-southeast-1"
  tags = {
    ResourceCategory = "vpc"
    ManagedBy        = "terraform"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = "aws-dev-vpc-1"
    }
  }
}

module "route_table" {
  source = "../../modules/route-table"

  vpc_id           = data.terraform_remote_state.vpc.outputs.id
  route_table_name = "private-route-table"

  routes = {
    default_gateway = {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = "nat-1aabcf10311be2582"
    }
  }

  tags = local.tags
}