output "association_id" {
  description = "ID of the EKS Pod Identity association."
  value       = aws_eks_pod_identity_association.this.association_id
}

output "association_arn" {
  description = "ARN of the EKS Pod Identity association."
  value       = aws_eks_pod_identity_association.this.association_arn
}

output "role_arn" {
  description = "IAM role ARN used by the association."
  value       = aws_eks_pod_identity_association.this.role_arn
}
