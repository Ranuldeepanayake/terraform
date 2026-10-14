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

  name                  = "CustomRoleTerraformDeploymentLimited"
  description           = "A role which has limited priviledges for Terraform"
  trust_policy          = file("${path.root}/policies/trust-policy.json")
  path                  = "/"
  max_session_duration  = 3600
  force_detach_policies = false
  permissions_boundary  = null

  inline_policies = {
    #  SecretsAccess = "${path.root}/policies/secrets-access.json"
  }

  external_policy_arns = [
    "arn:aws:iam::104322896078:policy/CustomPolicyAPIGatewayTerraformDeployment",
    "arn:aws:iam::104322896078:policy/CustomPolicyAssumeRole",
    "arn:aws:iam::104322896078:policy/CustomPolicyEKSCTL",
    "arn:aws:iam::104322896078:policy/CustomPolicyEKSExternalDNS",
    "arn:aws:iam::104322896078:policy/CustomPolicyEKSTerraformDeployment",
    "arn:aws:iam::104322896078:policy/CustomPolicyGlobalAdminsReadOnly",
    "arn:aws:iam::104322896078:policy/CustomPolicyIAMSuperAdminAssumeRole",
    "arn:aws:iam::104322896078:policy/CustomPolicyLambdaTerraformDeployment",
    "arn:aws:iam::104322896078:policy/CustomPolicySecretsManagerTerraformDeployment",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  ]

  tags = local.tags
}