# Locals for common variables.
locals {
  aws_region    = "ap-southeast-1"
  project_name  = "common-infra"

  tags = {
    Environment      = "dev"
    ProjectName      = local.project_name
    ResourceCategory = "vpc"
    ManagedBy        = "terraform"
  }
}

module "internet_gateway" {
  source = "../../modules/internet-gateway"

  name   = "default-internet-gateway"
  vpc_id = "vpc-02ae59b36d4cf20d7"
  tags   = local.tags
}