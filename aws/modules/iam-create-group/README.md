### Importing existing IAM group objects into the terraform caller.

## Gather information.
aws iam list-groups
aws iam get-group --group-name iac --query 'Group.[GroupName,Arn,Path]' --output table
aws iam get-group --group-name iac --query 'Users[*].[UserName,Arn]' --output table
# Inline group policies.
aws iam list-group-policies --group-name iac --query 'PolicyNames' --output table
aws iam get-group-policy --group-name iac --policy-name IacInlineAccess
# Attached external policies.
aws iam list-attached-group-policies --group-name iac --query 'AttachedPolicies[*].[PolicyName,PolicyArn]' --output table
aws iam get-policy --policy-arn <policy arn>


## Perform the import.
terraform import 'module.iam_create_group.aws_iam_group.this' terraform
# Import an internal user policy attachment.
terraform import 'module.iam_create_group.aws_iam_group_policy.this["IacInlineAccess"]' 'iac:IacInlineAccess'
# Import an external user policy attachment. 
terraform import 'module.iam_create_group.aws_iam_group_policy_attachment.this["arn:aws:iam::aws:policy/IAMFullAccess"]' 'iac/arn:aws:iam::aws:policy/IAMFullAccess'