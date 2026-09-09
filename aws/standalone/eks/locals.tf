locals {
  # Extract OIDC provider URL for use in IRSA trust policies.
  # Removes https:// prefix to match AWS OIDC provider naming convention.
  oidc_provider_url = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")

  # External DNS IAM policy ARN for the service account. 
  # If not provided, defaults to a policy named in var.external_dns_policy_name.
  external_dns_policy_arn = coalesce(var.external_dns_policy_arn, "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.external_dns_policy_name}")
}