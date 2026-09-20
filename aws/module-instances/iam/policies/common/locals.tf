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
      description = "Allows Terraform deployments for API Gateway resources."
      policy      = file("${path.root}/policies/CustomPolicyAPIGatewayTerraformDeployment.json")
      path        = "/"
    }

    CustomPolicyAssumeRole = {
      description = "Allows an IAM principal to assume the specified custom role."
      policy      = file("${path.root}/policies/CustomPolicyAssumeRole.json")
      path        = "/"
    }

    CustomPolicyEKSCTL = {
      description = "Allows EKSCTL operations for cluster lifecycle management."
      policy      = file("${path.root}/policies/CustomPolicyEKSCTL.json")
      path        = "/"
    }

    CustomPolicyEKSExternalDNS = {
      description = "Allows external-dns updates for EKS hosted zones and records."
      policy      = file("${path.root}/policies/CustomPolicyEKSExternalDNS.json")
      path        = "/"
    }

    CustomPolicyEKSTerraformDeployment = {
      description = "Allows Terraform deployments for EKS resources."
      policy      = file("${path.root}/policies/CustomPolicyEKSTerraformDeployment.json")
      path        = "/"
    }

    CustomPolicyGlobalAdminsReadOnly = {
      description = "Provides read-only access for global admin review and auditing."
      policy      = file("${path.root}/policies/CustomPolicyGlobalAdminsReadOnly.json")
      path        = "/"
    }

    CustomPolicyLambdaTerraformDeployment = {
      description = "Allows Terraform deployments for Lambda resources."
      policy      = file("${path.root}/policies/CustomPolicyLambdaTerraformDeployment.json")
      path        = "/"
    }

    CustomPolicySecretsManagerTerraformDeployment = {
      description = "Allows Terraform deployments for Secrets Manager resources."
      policy      = file("${path.root}/policies/CustomPolicySecretsManagerTerraformDeployment.json")
      path        = "/"
    }
  }
}