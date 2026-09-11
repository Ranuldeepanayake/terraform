output "eks_platform_workspace_name" {
  description = "Terraform Cloud workspace containing the EKS platform components."
  value       = var.eks_platform_workspace_name
}

output "argocd_ingress" {
  description = "Argo CD ingress metadata."
  value = {
    name          = kubernetes_manifest.argocd_ingress.manifest.metadata.name
    namespace     = kubernetes_manifest.argocd_ingress.manifest.metadata.namespace
    host          = kubernetes_manifest.argocd_ingress.manifest.spec.rules[0].host
    ingress_class = kubernetes_manifest.argocd_ingress.manifest.spec.ingressClassName
    service_name  = kubernetes_manifest.argocd_ingress.manifest.spec.rules[0].http.paths[0].backend.service.name
    service_port  = kubernetes_manifest.argocd_ingress.manifest.spec.rules[0].http.paths[0].backend.service.port.number
  }
}

output "cluster_issuers" {
  description = "Let's Encrypt ClusterIssuer metadata."
  value = {
    dns = {
      name = kubernetes_manifest.letsencrypt_dns.manifest.metadata.name
      kind = kubernetes_manifest.letsencrypt_dns.manifest.kind
    }

    http = {
      name = kubernetes_manifest.letsencrypt_http.manifest.metadata.name
      kind = kubernetes_manifest.letsencrypt_http.manifest.kind
    }
  }
}

output "ebs_storage_class" {
  description = "EBS CSI StorageClass metadata."
  value = {
    name                   = kubernetes_manifest.ebs_sc.manifest.metadata.name
    provisioner            = kubernetes_manifest.ebs_sc.manifest.provisioner
    volume_binding_mode    = kubernetes_manifest.ebs_sc.manifest.volumeBindingMode
    reclaim_policy         = kubernetes_manifest.ebs_sc.manifest.reclaimPolicy
    allow_volume_expansion = kubernetes_manifest.ebs_sc.manifest.allowVolumeExpansion
  }
}