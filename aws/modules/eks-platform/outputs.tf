output "eks_cluster_workspace_name" {
  description = "Terraform Cloud workspace containing the EKS cluster."
  value       = var.eks_cluster_workspace_name
}

output "platform_releases" {
  description = "Installed EKS platform Helm releases."
  value = {
    metrics_server = {
      name      = helm_release.metrics_server.name
      namespace = helm_release.metrics_server.namespace
      status    = helm_release.metrics_server.status
      revision  = helm_release.metrics_server.metadata[0].revision
    }

    nginx_ingress = {
      name      = helm_release.nginx_ingress.name
      namespace = helm_release.nginx_ingress.namespace
      status    = helm_release.nginx_ingress.status
      revision  = helm_release.nginx_ingress.metadata[0].revision
    }

    cert_manager = {
      name      = helm_release.cert_manager.name
      namespace = helm_release.cert_manager.namespace
      status    = helm_release.cert_manager.status
      revision  = helm_release.cert_manager.metadata[0].revision
    }

    argocd = {
      name      = helm_release.argocd.name
      namespace = helm_release.argocd.namespace
      status    = helm_release.argocd.status
      revision  = helm_release.argocd.metadata[0].revision
    }
  }
}