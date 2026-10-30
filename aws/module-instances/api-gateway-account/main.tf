locals {
  project_name = "student-application"

  tags = {
    ProjectName      = local.project_name
    ResourceCategory = "api-gateway"
    ManagedBy        = "terraform"
  }
}

module "api_gateway_account" {
  source = "../../modules/api-gateway-account"

  role_name = "${local.project_name}-api-gateway-cloudwatch"
  tags      = local.tags
}
