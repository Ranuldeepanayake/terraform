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