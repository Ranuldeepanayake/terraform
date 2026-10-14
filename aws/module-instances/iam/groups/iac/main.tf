# Locals for common variables.
locals {
  aws_region = "ap-southeast-1"
}

module "iam_create_group" {
  source = "../../../../modules/iam-create-group"

  name = "iac"
  path = "/"

  #inline_policies = {
  #  "IacInlineAccess" = "${path.root}/policies/policy.json"
  #}

  external_policy_arns = []
}