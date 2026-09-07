locals {
  project_name = "test-project"
  secret_name  = "database-credentials"

  tags = {
    Environment      = "dev"
    ProjectName      = local.project_name
    ResourceCategory = "secret"
    ManagedBy        = "terraform"
  }
}

module "secret" {
  source = "../../modules/secrets-manager"

  name          = "${local.project_name}/${local.secret_name}"
  description   = "Database credentials for ${local.project_name}"
  secret_string = jsonencode(var.secret_values)
  kms_key_id    = null
  tags          = local.tags
}