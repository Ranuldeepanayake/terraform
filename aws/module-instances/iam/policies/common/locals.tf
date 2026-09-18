# Locals for common variables.
locals {
  aws_region = "ap-southeast-1"
  tags = {
    ResourceCategory = "iam"
    ManagedBy        = "terraform"
  }

  policies = {
    CustomPolicyIAMSuperAdminAssumeRole = {
      description = "Allows an IAM object to assume the specified super admin role."
      policy      = file("${path.root}/policies/CustomPolicyIAMSuperAdminAssumeRole.json")
      path        = "/"
    }
  }
}