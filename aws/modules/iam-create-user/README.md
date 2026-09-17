### Importing existing IAM user objects into the terraform caller.

## Gather information.
aws iam list-users
aws iam list-groups-for-user --user-name <user> --query 'Groups[*].GroupName' --output table
aws iam get-login-profile --user-name <user>
aws iam list-access-keys --user-name <user> --query 'AccessKeyMetadata[*].[AccessKeyId,Status,CreateDate]' --output table
# Inline user policies.
aws iam list-user-policies --user-name <user>
aws iam get-user-policy --user-name <user> --policy-name TerraformInlineAccess
# Attached external policies.
aws iam list-attached-user-policies --user-name <user> --query 'AttachedPolicies[*].[PolicyName,PolicyArn]' --output table
aws iam get-policy --policy-arn arn:aws:iam::104322896078:policy/CustomPolicy


## Perform the import.
terraform import 'module.iam_create_user.aws_iam_user.this' terraform
terraform import 'module.iam_create_user.aws_iam_user_group_membership.this[0]' 'terraform/iac'
terraform import 'module.iam_create_user.aws_iam_user_login_profile.this[0]' terraform
terraform import 'module.iam_create_user.aws_iam_access_key.this[0]' ACCESS_KEY_ID
# Import an internal user policy attachment.
terraform import 'module.iam_create_user.aws_iam_user_policy.this["TerraformInlineAccess"]' 'terraform:TerraformInlineAccess'
# Import an external user policy attachment. 
terraform import 'module.iam_create_user.aws_iam_user_policy_attachment.this["arn:aws:iam::104322896078:policy/CustomPolicy"]' \
'terraform/arn:aws:iam::104322896078:policy/CustomPolicy'