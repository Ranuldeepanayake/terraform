# Locals for common variables.
locals {
  aws_region = "ap-southeast-1"
  tags = {
    ResourceCategory = "vpc"
    ManagedBy        = "terraform"
    Exposure         = "public"
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

data "terraform_remote_state" "internet_gateway" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = "aws-dev-igw-1"
    }
  }
}

module "route_table" {
  source = "../../modules/route-table"

  vpc_id           = data.terraform_remote_state.vpc.outputs.id
  route_table_name = "public-route-table"

  routes = {
    ipv4_default_gateway = {
      cidr_block = "0.0.0.0/0"
      gateway_id = data.terraform_remote_state.internet_gateway.outputs.id
    },
    ipv6_default_gateway = {
      ipv6_cidr_block = "::/0"
      gateway_id      = data.terraform_remote_state.internet_gateway.outputs.id
    }
  }

  tags = local.tags
}