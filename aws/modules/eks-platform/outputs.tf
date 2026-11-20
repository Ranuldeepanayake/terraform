output "eks_cluster_workspace_name" {
  description = "Terraform Cloud workspace containing the EKS cluster."
  value       = var.eks_cluster_workspace_name
}

output "platform_releases" {
  description = "Installed EKS platform Helm releases."
  value = {
    metrics_server = {
      name      = try(helm_release.metrics_server[0].name, null)
      namespace = try(helm_release.metrics_server[0].namespace, null)
      version   = try(helm_release.metrics_server[0].version, null)
      status    = try(helm_release.metrics_server[0].status, null)
      revision  = try(helm_release.metrics_server[0].metadata[0].revision, null)
    }

    nginx_ingress = {
      name      = try(helm_release.nginx_ingress[0].name, null)
      namespace = try(helm_release.nginx_ingress[0].namespace, null)
      version   = try(helm_release.nginx_ingress[0].version, null)
      status    = try(helm_release.nginx_ingress[0].status, null)
      revision  = try(helm_release.nginx_ingress[0].metadata[0].revision, null)
    }

    cert_manager = {
      name      = try(helm_release.cert_manager[0].name, null)
      namespace = try(helm_release.cert_manager[0].namespace, null)
      version   = try(helm_release.cert_manager[0].version, null)
      status    = try(helm_release.cert_manager[0].status, null)
      revision  = try(helm_release.cert_manager[0].metadata[0].revision, null)
    }

    argocd = {
      name      = try(helm_release.argocd[0].name, null)
      namespace = try(helm_release.argocd[0].namespace, null)
      version   = try(helm_release.argocd[0].version, null)
      status    = try(helm_release.argocd[0].status, null)
      revision  = try(helm_release.argocd[0].metadata[0].revision, null)
    }

    istio_base = try({
      name      = helm_release.istio_base[0].name
      namespace = helm_release.istio_base[0].namespace
      version   = helm_release.istio_base[0].version
      status    = helm_release.istio_base[0].status
      revision  = helm_release.istio_base[0].metadata[0].revision
    }, null)

    istiod = try({
      name      = helm_release.istiod[0].name
      namespace = helm_release.istiod[0].namespace
      version   = helm_release.istiod[0].version
      status    = helm_release.istiod[0].status
      revision  = helm_release.istiod[0].metadata[0].revision
    }, null)
  }
}

output "istio_enabled" {
  description = "Whether Istio is managed by this platform module."
  value       = var.addons.istio.enabled
}