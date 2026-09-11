variable "eks_cluster_workspace_name" {
  description = "The name of the workspace where the EKS infrastructure is deployed."
  type        = string
}

variable "argocd_values" {
  description = "Argo CD Helm values"
  type        = string
  default     = ""
}