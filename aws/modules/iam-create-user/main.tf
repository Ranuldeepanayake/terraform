# Creates the IAM user.
resource "aws_iam_user" "this" {
  name = var.username
  path = var.path

  tags = merge(
    var.tags,
    {
      ResourceType = "IAMUser"
    }
  )
}

# Creates an IAM login profile for users who need to access the AWS Management Console using a username and password.
resource "aws_iam_user_login_profile" "this" {
  count = var.create_console_login ? 1 : 0

  user                    = aws_iam_user.this.name
  password_length         = var.password_length
  password_reset_required = var.password_reset_required
}

# Creates an access key for programmatic access to AWS APIs.
resource "aws_iam_access_key" "this" {
  count = var.create_access_key ? 1 : 0

  user = aws_iam_user.this.name
}

# Adds the IAM user to the specified existing IAM groups.
resource "aws_iam_user_group_membership" "this" {
  count = length(var.groups) > 0 ? 1 : 0

  user   = aws_iam_user.this.name
  groups = var.groups
}

# Creates an inline policy for the IAM user.
resource "aws_iam_user_policy" "this" {
  for_each = var.inline_policies

  name   = each.key
  user   = aws_iam_user.this.name
  policy = file(each.value)
}

# Attach the specified external IAM policies to the user.
resource "aws_iam_user_policy_attachment" "this" {
  for_each = toset(var.external_policy_arns)

  user       = aws_iam_user.this.name
  policy_arn = each.value
}