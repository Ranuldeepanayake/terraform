# Create the IAM role.
resource "aws_iam_role" "this" {
  name                  = var.name
  description           = var.description
  path                  = var.path
  assume_role_policy    = var.trust_policy
  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies
  permissions_boundary  = var.permissions_boundary

  tags = merge(
    var.tags,
    {
      ResourceType = "IAMRole"
    }
  )
}

# Create inline policies for the IAM role if specified.
resource "aws_iam_role_policy" "this" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.name
  policy = file(each.value)
}

# Attach the specified external IAM policies to the role.
resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.external_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}