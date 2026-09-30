# Locals for common variables.
locals {
  aws_region   = "ap-southeast-1"
  project_name = "s3-app"

  tags = {
    ResourceCategory = "iam"
    ManagedBy        = "terraform"
    ProjectName      = local.project_name
  }
}

module "iam_create_role" {
  source = "../../../../modules/iam-create-role"

  name                  = "CustomRoleEKSPodS3App"
  description           = "A role which can be assumed by EKS pods of ${local.project_name}"
  trust_policy          = file("${path.root}/policies/trust-policy.json")
  path                  = "/"
  max_session_duration  = 3600
  force_detach_policies = false
  permissions_boundary  = null

  inline_policies = {
    RDSAccess = "${path.root}/policies/inline-rds.json"
  }

  #external_policy_arns = [
  #  "arn:aws:iam::aws:policy/AdministratorAccess"
  #]

  tags = local.tags
}