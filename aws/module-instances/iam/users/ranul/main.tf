# Locals for common variables.
locals {
  aws_region = "ap-southeast-1"
  tags = {
    ResourceCategory = "iam"
    ManagedBy        = "terraform"
  }
}

module "iam_create_user" {
  source = "../../../../modules/iam-create-user"

  username                = "ranul"
  path                    = "/"
  create_console_login    = true
  password_length         = 12
  password_reset_required = true
  create_access_key       = false
  groups = [
  ]

  # Inline policies created by this module.
  #inline_policies = {
  #  "TerraformInlineAccess" = "${path.root}/policies/terraform-inline.json"
  #}

  # Existing policies that this module should attach.
  external_policy_arns = [
    "arn:aws:iam::104322896078:policy/CustomPolicyIAMSuperAdminAssumeRole"
  ]

  tags = local.tags
}