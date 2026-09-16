# Locals for common variables.
locals {
  aws_region = "ap-southeast-1"
  tags = {
    ResourceCategory = "iam"
    ManagedBy        = "terraform"
  }
}

module "iam_create_role" {
  source = "../../../../modules/iam-create-role"

  name                  = "CustomRoleSuperAdmin"
  description           = "A role which has super administrator priviledges."
  trust_policy          = file("${path.root}/policy.json")
  path                  = "/"
  max_session_duration  = 3600
  force_detach_policies = false
  permissions_boundary  = null
  tags                  = local.tags
}