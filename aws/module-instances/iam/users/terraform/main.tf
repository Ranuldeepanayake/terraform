# Locals for common variables.
locals {
  aws_region = "ap-southeast-1"
  tags = {
    AKIARQSRBCDHGI3X5WPK = "superuser access"
    ResourceCategory     = "iam"
    ManagedBy            = "terraform"
  }
}

module "iam_create_user" {
  source = "../../../../modules/iam-create-user"

  username                = "terraform"
  path                    = "/"
  create_console_login    = true
  password_reset_required = false
  create_access_key       = true
  groups = [
    "iac"
  ]
  tags = local.tags
}