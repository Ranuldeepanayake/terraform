# Cluster isuuer using DNS01 challenge with Route53. Requires IAM setup in the iam.tf file for cert-manager 
# to manage Route53 records using pod identity access. The below implementation supports multiple Route53 zones
# for DNS-01 challenge validation. The zones are defined in the terraform.tfvars file and passed to the module 
# as a map variable.
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
          for zone in var.route53_zones : {
            selector = {
              dnsZones = [
                zone.dns_zone
              ]
            }

            dns01 = {
              route53 = {
                hostedZoneID = zone.zone_id
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager,
    data.terraform_remote_state.eks_cluster
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
    helm_release.cert_manager,
    data.terraform_remote_state.eks_cluster
  ]
}