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

  #inline_policies = {
  #  S3Access      = "${path.root}/policies/s3-access.json"
  #  SecretsAccess = "${path.root}/policies/secrets-access.json"
  #}

  external_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  tags = local.tags
}