output "eks_cluster_workspace_name" {
  description = "Terraform Cloud workspace containing the EKS cluster."
  value       = module.eks_platform.eks_cluster_workspace_name
}

output "platform_releases" {
  description = "Installed EKS platform Helm releases."
  value       = module.eks_platform.platform_releases
}