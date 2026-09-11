resource "kubernetes_manifest" "argocd_ingress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"

    metadata = {
      name      = "argocd"
      namespace = "argocd"
    }

    spec = {
      ingressClassName = "nginx"

      rules = [
        {
          host = "argocd.ranul.click"

          http = {
            paths = [
              {
                path     = "/"
                pathType = "Prefix"

                backend = {
                  service = {
                    name = "argocd-server"

                    port = {
                      number = 80
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  }

  depends_on = [
    data.terraform_remote_state.eks_platform
  ]
}