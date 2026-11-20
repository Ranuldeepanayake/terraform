# Install metrics server via Helm. Metrics Server is required for Horizontal Pod Autoscaling and resource metrics.
resource "helm_release" "metrics_server" {
  count      = var.addons.metrics_server.enabled ? 1 : 0
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.addons.metrics_server.version

  depends_on = [
    data.terraform_remote_state.eks_cluster
  ]

  lifecycle {
    ignore_changes = [version]
  }
}

# Install Nginx ingress controller with Helm.
resource "helm_release" "nginx_ingress" {
  count            = var.addons.nginx_ingress.enabled ? 1 : 0
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.addons.nginx_ingress.version

  depends_on = [
    data.terraform_remote_state.eks_cluster
  ]

  lifecycle {
    ignore_changes = [version]
  }
}

# Install cert-manager with Helm.
resource "helm_release" "cert_manager" {
  count            = var.addons.cert_manager.enabled ? 1 : 0
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.addons.cert_manager.version

  set {
    name  = "crds.enabled"
    value = "true"
  }

  depends_on = [
    data.terraform_remote_state.eks_cluster
  ]

  lifecycle {
    ignore_changes = [version]
  }
}

# Install ArgoCD with Helm.
resource "helm_release" "argocd" {
  count      = var.addons.argocd.enabled ? 1 : 0
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.addons.argocd.version

  namespace        = "argocd"
  create_namespace = true

  values = [
    var.argocd_values
  ]

  # Optional
  # version = "7.8.26"

  lifecycle {
    ignore_changes = [version]
  }
}

# Install Istio's CRDs before its control plane. Istio is opt-in because it
# adds a proxy to enrolled workloads and requires deliberate namespace rollout.
resource "helm_release" "istio_base" {
  count = var.addons.istio.enabled ? 1 : 0

  name             = "istio-base"
  repository       = "https://blob.istio.io/istio-release/charts"
  chart            = "base"
  version          = var.addons.istio.version
  namespace        = var.addons.istio.namespace
  create_namespace = true
  atomic           = true
  timeout          = 600

  set {
    name  = "defaultRevision"
    value = "default"
  }

  set {
    name  = "global.istioNamespace"
    value = var.addons.istio.namespace
  }

  depends_on = [
    data.terraform_remote_state.eks_cluster
  ]

  lifecycle {
    ignore_changes = [version]
  }
}

resource "helm_release" "istiod" {
  count = var.addons.istio.enabled ? 1 : 0

  name       = "istiod"
  repository = "https://blob.istio.io/istio-release/charts"
  chart      = "istiod"
  version    = var.addons.istio.version
  namespace  = var.addons.istio.namespace
  atomic     = true
  timeout    = 600

  set {
    name  = "global.istioNamespace"
    value = var.addons.istio.namespace
  }

  depends_on = [
    helm_release.istio_base
  ]

  lifecycle {
    ignore_changes = [version]
  }
}
