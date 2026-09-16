# Locals for common variables.
locals {
  aws_region = "ap-southeast-1"
  tags = {
    ResourceCategory = "iam"
    ManagedBy        = "terraform"
  }
}

module "iam_create_policy" {
  source = "../../../../modules/iam-create-policy"

  name        = "CustomPolicyIAMSuperAdminAssumeRole"
  description = "Allows an IAM object to assume the specified super admin role."
  policy      = file("${path.root}/policy.json")
  path        = "/"
  tags        = local.tags
}