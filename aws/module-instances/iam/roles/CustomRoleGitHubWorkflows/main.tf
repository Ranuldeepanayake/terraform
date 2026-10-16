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

  name                  = "CustomRoleGitHubWorkflows"
  description           = "A role which can be assumed by GitHub workflows to perform actions on AWS resources."
  trust_policy          = file("${path.root}/policies/trust-policy.json")
  path                  = "/"
  max_session_duration  = 3600
  force_detach_policies = false
  permissions_boundary  = null

  inline_policies = {
    ECRAccess = "${path.root}/policies/inline-ecr.json"
  }

  external_policy_arns = []

  tags = local.tags
}