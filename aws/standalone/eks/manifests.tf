# Cluster isuuer using DNS01 challenge with Route53. Requires IAM setup in the iam.tf file for cert-manager 
# to manage Route53 records using pod identity access.
resource "kubernetes_manifest" "letsencrypt_dns" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = "letsencrypt-dns"
    }

    spec = {
      acme = {
        email  = var.letsencrypt_email_address
        server = "https://acme-v02.api.letsencrypt.org/directory"

        privateKeySecretRef = {
          name = "letsencrypt-dns"
        }

        solvers = [
          {
            dns01 = {
              route53 = {}
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager,
    aws_eks_pod_identity_association.cert_manager
  ]
}

# Cluster issuer using HTTP01 challenge with NGINX ingress. Requires port 80 to be open in the ALB security group.
# This can be used as a fallback if DNS01 challenge is not possible due to DNS provider limitations.
resource "kubernetes_manifest" "letsencrypt_http" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = "letsencrypt-http"
    }

    spec = {
      acme = {
        email  = var.letsencrypt_email_address
        server = "https://acme-v02.api.letsencrypt.org/directory"

        privateKeySecretRef = {
          name = "letsencrypt-http"
        }

        solvers = [
          {
            http01 = {
              ingress = {
                ingressClassName = "nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager
  ]
}