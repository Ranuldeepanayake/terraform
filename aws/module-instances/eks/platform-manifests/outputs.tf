output "eks_platform_workspace_name" {
  description = "Terraform Cloud workspace containing the EKS platform components."
  value       = module.eks_platform_manifests.eks_platform_workspace_name
}

output "argocd_ingress" {
  description = "Argo CD ingress metadata."
  value       = module.eks_platform_manifests.argocd_ingress
}

output "cluster_issuers" {
  description = "Let's Encrypt ClusterIssuer metadata."
  value       = module.eks_platform_manifests.cluster_issuers
}

output "ebs_storage_class" {
  description = "EBS CSI StorageClass metadata."
  value       = module.eks_platform_manifests.ebs_storage_class
}