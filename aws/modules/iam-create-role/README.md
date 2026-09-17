
### Importing existing IAM user objects into the terraform caller.

## Gather information.
aws iam list-roles --query 'Roles[].{Name:RoleName,Arn:Arn}' --output table
aws iam list-role-policies --role-name CustomRoleSuperAdmin
aws iam get-role-policy --role-name CustomRoleSuperAdmin --policy-name S3Access
aws iam list-attached-role-policies --role-name

## Perform the import.
terraform import 'module.iam_create_role.aws_iam_role.this' 'CustomRoleSuperAdmin'
# Import an internal role policy attachment.
terraform import 'module.iam_create_role.aws_iam_role_policy.this["S3Access"]' 'CustomRoleSuperAdmin:S3Access'
# Import an external role policy attachment. 
terraform import 'module.iam_create_role.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AdministratorAccess"]' \
'CustomRoleSuperAdmin/arn:aws:iam::aws:policy/AdministratorAccess'