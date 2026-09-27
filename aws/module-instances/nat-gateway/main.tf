# Locals for common variables.
locals {
  aws_region                      = "ap-southeast-1"
  subnet_workspace_name           = "aws-dev-subnet-public"
  internet_gateway_workspace_name = "aws-dev-igw-1"
  subnet_key                      = "a"

  tags = {
    ResourceCategory = "vpc"
    ManagedBy        = "terraform"
  }
}

data "terraform_remote_state" "subnet_public" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = local.subnet_workspace_name
    }
  }
}

data "terraform_remote_state" "internet_gateway" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = local.internet_gateway_workspace_name
    }
  }
}

module "nat_gateway" {
  source = "../../modules/nat-gateway"

  name                = "my-nat-gateway"
  subnet_id           = data.terraform_remote_state.subnet_public.outputs.subnet_ids[local.subnet_key]
  connectivity_type   = "public"
  internet_gateway_id = data.terraform_remote_state.internet_gateway.outputs.id

  tags = local.tags
}