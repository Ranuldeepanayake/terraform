# Locals for common variables.
locals {
  aws_region   = "ap-southeast-1"
  project_name = "common-infra"
  tags = {
    ProjectName      = local.project_name
    ResourceCategory = "iam"
    ManagedBy        = "terraform"
    Exposure         = "Public"
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

data "terraform_remote_state" "route_table" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = "aws-dev-route-table-public"
    }
  }
}

module "subnet" {
  source = "../../modules/subnet"

  vpc_id = data.terraform_remote_state.vpc.outputs.id

  subnets = {
    a = {
      cidr_block                      = "10.0.1.0/24"
      ipv6_cidr_block                 = "2406:da18:1a61:b701::/64"
      assign_ipv6_address_on_creation = true
      availability_zone               = "ap-southeast-1a"
      map_public_ip_on_launch         = true
      route_table_id                  = data.terraform_remote_state.route_table.outputs.route_table_id
      tags = {
        Name = "${local.project_name}_subnet-a"
        az   = "ap-southeast-1a"
      }
    }

    b = {
      cidr_block                      = "10.0.2.0/24"
      ipv6_cidr_block                 = "2406:da18:1a61:b702::/64"
      assign_ipv6_address_on_creation = true
      availability_zone               = "ap-southeast-1b"
      map_public_ip_on_launch         = true
      route_table_id                  = data.terraform_remote_state.route_table.outputs.route_table_id
      tags = {
        Name = "${local.project_name}_subnet-b"
        az   = "ap-southeast-1b"
      }
    }
  }

  tags = local.tags
}