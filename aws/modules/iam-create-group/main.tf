# Create the IAM group.
resource "aws_iam_group" "this" {
  name = var.name
  path = var.path
}

# Creates inline policies for the IAM group if specified.
resource "aws_iam_group_policy" "this" {
  for_each = var.inline_policies

  name   = each.key
  group  = aws_iam_group.this.name
  policy = file(each.value)
}

# Attach the specified external IAM policies to the group.
resource "aws_iam_group_policy_attachment" "this" {
  for_each = var.external_policy_arns

  group      = aws_iam_group.this.name
  policy_arn = each.value
}