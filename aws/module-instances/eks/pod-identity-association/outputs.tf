output "association_id" {
  description = "ID of the EKS Pod Identity association."
  value       = module.pod_identity_association.association_id
}

output "association_arn" {
  description = "ARN of the EKS Pod Identity association."
  value       = module.pod_identity_association.association_arn
}

output "cluster_name" {
  description = "EKS cluster used by the association."
  value       = data.terraform_remote_state.eks.outputs.cluster_id
}

output "role_arn" {
  description = "IAM role associated with the service account."
  value       = module.pod_identity_association.role_arn
}
