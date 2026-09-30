resource "aws_eks_pod_identity_association" "this" {
  cluster_name         = var.cluster_name
  namespace            = var.namespace
  service_account      = var.service_account
  role_arn             = var.role_arn
  disable_session_tags = var.disable_session_tags
  target_role_arn      = var.target_role_arn

  tags = merge(
    var.tags,
    {
      ResourceType = "eks-pod-identity-association"
    }
  )
}
