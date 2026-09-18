### Importing existing IAM group objects into the terraform caller.

## Gather information.
aws iam list-policies --scope Local --query 'Policies[*].[PolicyName,PolicyId,Arn,Path,DefaultVersionId]' --output table
aws iam get-policy --policy-arn <policy arn>

## Perform the import.
terraform import 'module.iam_create_policy["CustomPolicyIAMSuperAdminAssumeRole"].aws_iam_policy.this'  'arn:aws:iam::104322896078:policy/CustomPolicyIAMSuperAdminAssumeRole'