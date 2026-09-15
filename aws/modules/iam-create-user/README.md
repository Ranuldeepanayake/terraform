# How to import existing objects into the terraform caller.

# Gather information.

aws iam list-users
aws iam list-groups-for-user --user-name <user> --query 'Groups[*].GroupName' --output table
aws iam get-login-profile --user-name <user>
aws iam list-access-keys --user-name <user> --query 'AccessKeyMetadata[*].[AccessKeyId,Status,CreateDate]' --output table


# Perform the import.
terraform import 'module.iam_create_user.aws_iam_user.this' terraform
terraform import 'module.iam_create_user.aws_iam_user_group_membership.this[0]' 'terraform/iac'
terraform import 'module.iam_create_user.aws_iam_user_login_profile.this[0]' terraform
terraform import 'module.iam_create_user.aws_iam_access_key.this[0]' ACCESS_KEY_ID