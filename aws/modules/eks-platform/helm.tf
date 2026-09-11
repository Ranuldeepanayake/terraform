# Install metrics server via Helm. Metrics Server is required for Horizontal Pod Autoscaling and resource metrics.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  depends_on = [
    data.terraform_remote_state.eks_cluster
  ]
}

# Install Nginx ingress controller with Helm.
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  depends_on = [
    data.terraform_remote_state.eks_cluster
  ]
}

# Install cert-manager with Helm.
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"

  set {
    name  = "crds.enabled"
    value = "true"
  }

  depends_on = [
    data.terraform_remote_state.eks_cluster
  ]
}

# Install ArgoCD with Helm.
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  namespace        = "argocd"
  create_namespace = true

  values = [
    var.argocd_values
  ]

  # Optional
  # version = "7.8.26"
}