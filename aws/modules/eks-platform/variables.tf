variable "eks_cluster_workspace_name" {
  description = "The name of the workspace where the EKS infrastructure is deployed."
  type        = string
}

variable "letsencrypt_email_address" {
  description = "Email address registered with Let's Encrypt for ACME account notifications."
  type        = string

  validation {
    condition = can(regex(
      "^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
      var.letsencrypt_email_address
    ))

    error_message = "letsencrypt_email must be a valid email address."
  }
}

variable "route53_zones" {
  description = "Route 53 hosted zones that cert-manager can use for DNS-01 validation."

  type = map(object({
    zone_id  = string
    dns_zone = string
  }))
}