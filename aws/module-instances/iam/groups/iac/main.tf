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

  external_policy_arns = [
   "arn:aws:iam::104322896078:policy/CustomPolicyEKSCTL",                             
   "arn:aws:iam::104322896078:policy/CustomPolicyLambdaTerraformDeployment",          
   "arn:aws:iam::104322896078:policy/CustomPolicyAPIGatewayTerraformDeployment",      
   "arn:aws:iam::104322896078:policy/CustomPolicyAssumeRole",                         
   "arn:aws:iam::104322896078:policy/CustomPolicyGlobalAdminsReadOnly",               
   "arn:aws:iam::104322896078:policy/CustomPolicySecretsManagerTerraformDeployment",  
   "arn:aws:iam::104322896078:policy/CustomPolicyEKSTerraformDeployment",             
   "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",                    
   "arn:aws:iam::aws:policy/AmazonVPCFullAccess"                          
  ]
}