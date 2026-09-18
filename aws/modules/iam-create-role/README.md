
### Importing existing IAM role objects into the terraform caller.

## Gather information.
aws iam list-roles --query 'Roles[].{Name:RoleName,Arn:Arn}' --output table
# Inline user policies.
aws iam list-role-policies --role-name <role name>
aws iam get-role-policy --role-name <role name> --policy-name S3Access
# Attached external policies.
aws iam list-attached-role-policies --role-name <role name>
aws iam get-policy --policy-arn <policy arn>


## Perform the import.
terraform import 'module.iam_create_role.aws_iam_role.this' 'CustomRoleSuperAdmin'
# Import an internal role policy attachment.
terraform import 'module.iam_create_role.aws_iam_role_policy.this["S3Access"]' 'CustomRoleSuperAdmin:S3Access'
# Import an external role policy attachment. 
terraform import 'module.iam_create_role.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AdministratorAccess"]' \
'CustomRoleSuperAdmin/arn:aws:iam::aws:policy/AdministratorAccess'