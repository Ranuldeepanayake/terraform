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

    CustomPolicyAPIGatewayTerraformDeployment = {
      description = "Policy with required permissions to deploy an API gateway with Terraform"
      policy      = file("${path.root}/policies/CustomPolicyAPIGatewayTerraformDeployment.json")
      path        = "/"
    }

    CustomPolicyAssumeRole = {
      description = "Allows an entity attached with this policy to assume any role"
      policy      = file("${path.root}/policies/CustomPolicyAssumeRole.json")
      path        = "/"
    }

    CustomPolicyEKSCTL = {
      description = "Permissions needed to run common eksctl commands"
      policy      = file("${path.root}/policies/CustomPolicyEKSCTL.json")
      path        = "/"
    }

    CustomPolicyEKSExternalDNS = {
      description = "Allows external-dns updates for EKS hosted zones and records."
      policy      = file("${path.root}/policies/CustomPolicyEKSExternalDNS.json")
      path        = "/"
    }

    CustomPolicyEKSTerraformDeployment = {
      description = "Policy with required permissions to deploy an EKS cluster with Terraform"
      policy      = file("${path.root}/policies/CustomPolicyEKSTerraformDeployment.json")
      path        = "/"
    }

    CustomPolicyGlobalAdminsReadOnly = {
      description = "Read only commands for most service for Admins"
      policy      = file("${path.root}/policies/CustomPolicyGlobalAdminsReadOnly.json")
      path        = "/"
    }

    CustomPolicyLambdaTerraformDeployment = {
      description = "Policy with required permissions to deploy a Lambda function with Terraform"
      policy      = file("${path.root}/policies/CustomPolicyLambdaTerraformDeployment.json")
      path        = "/"
    }

    CustomPolicySecretsManagerTerraformDeployment = {
      description = "Allows Terraform to perform common operations with the Secrets Manager"
      policy      = file("${path.root}/policies/CustomPolicySecretsManagerTerraformDeployment.json")
      path        = "/"
    }
  }
}