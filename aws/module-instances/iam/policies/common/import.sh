#!/bin/bash

# Bash script to import a set of existing IAM policies into terraform.

for name in \
  CustomPolicyIAMSuperAdminAssumeRole \
  CustomPolicyAPIGatewayTerraformDeployment \
  CustomPolicyAssumeRole \
  CustomPolicyEKSCTL \
  CustomPolicyEKSExternalDNS \
  CustomPolicyEKSTerraformDeployment \
  CustomPolicyGlobalAdminsReadOnly \
  CustomPolicyLambdaTerraformDeployment \
  CustomPolicySecretsManagerTerraformDeployment
do
  terraform import \
    "module.iam_create_policy[\"${name}\"].aws_iam_policy.this" \
    "arn:aws:iam::104322896078:policy/${name}"
done