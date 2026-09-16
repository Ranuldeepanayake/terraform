### Importing existing IAM user objects into the terraform caller.

## Gather information.
aws iam list-users
aws iam list-groups-for-user --user-name <user> --query 'Groups[*].GroupName' --output table
aws iam get-login-profile --user-name <user>
aws iam list-access-keys --user-name <user> --query 'AccessKeyMetadata[*].[AccessKeyId,Status,CreateDate]' --output table
# Inline user policies.
aws iam list-user-policies --user-name my-existing-user 
# Attached external policies.
aws iam list-attached-user-policies --user-name my-existing-user


## Perform the import.
terraform import 'module.iam_create_user.aws_iam_user.this' terraform
terraform import 'module.iam_create_user.aws_iam_user_group_membership.this[0]' 'terraform/iac'
terraform import 'module.iam_create_user.aws_iam_user_login_profile.this[0]' terraform
terraform import 'module.iam_create_user.aws_iam_access_key.this[0]' ACCESS_KEY_ID
# Inline user policies.
terraform import aws_iam_user_policy.my_inline_policy 'my-existing-user:MyInlinePolicy'
# Policy attachment.
terraform import aws_iam_user_policy_attachment.my_policy 'my-existing-user/arn:aws:iam::123456789012:policy/MyPolicy'

resource "aws_iam_user_policy" "my_inline_policy" {
  name = "MyInlinePolicy"
  user = aws_iam_user.this.name

  policy = jsonencode({
    # existing policy goes here
  })
}