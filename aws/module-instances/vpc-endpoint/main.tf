# Locals for common variables.
locals {
  vpc_cidr_ipv4 = "10.0.0.0/16"
  vpc_cidr_ipv6 = "2406:da18:1a61:b700::/56"

  tags = {
    Environment      = "dev"
    ResourceCategory = "vpc-endpoint"
    ManagedBy        = "terraform"
  }
}

# Using a remote state data source to retrieve the VPC ID from another Terraform workspace. This allows us to reference a VPC that was created in a different
# root workspace. 
data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = "aws-dev-vpc-1"
    }
  }
}

module "vpc_endpoint" {
  source = "../../modules/vpc-endpoint"

  endpoint_name = "secrets-manager"
  vpc_id        = data.terraform_remote_state.vpc.outputs.id
  service_name  = "com.amazonaws.${var.aws_region}.secretsmanager"

  subnet_ids = [
    "subnet-089b9610c4dee02f4",
    "subnet-0776c6b9deb42264e"
  ]

  create_security_group = true

  security_group_ingress_rules = [
    {
      description = "Allow HTTPS from VPC IPv4"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_ipv4   = local.vpc_cidr_ipv4
    },
    {
      description = "Allow HTTPS from VPC IPv6"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_ipv6   = local.vpc_cidr_ipv6
    }
  ]

  security_group_egress_rules = [
    {
      description = "Allow outbound traffic IPv4"
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    },
    {
      description = "Allow outbound traffic IPv6"
      protocol    = "-1"
      cidr_ipv6   = "::/0"
    }
  ]

  tags = local.tags
}