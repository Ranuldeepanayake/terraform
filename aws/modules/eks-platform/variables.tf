variable "eks_cluster_workspace_name" {
  description = "The name of the workspace where the EKS infrastructure is deployed."
  type        = string
}

variable "argocd_values" {
  description = "Argo CD Helm values"
  type        = string
  default     = ""
}

variable "addons" {
  description = "Enablement and optional initial chart versions for each EKS platform add-on. An unset version installs the latest chart."
  type = object({
    metrics_server = optional(object({
      enabled = optional(bool, true)
      version = optional(string)
    }), {})
    nginx_ingress = optional(object({
      enabled = optional(bool, true)
      version = optional(string)
    }), {})
    cert_manager = optional(object({
      enabled = optional(bool, true)
      version = optional(string)
    }), {})
    argocd = optional(object({
      enabled = optional(bool, true)
      version = optional(string)
    }), {})
    istio = optional(object({
      enabled   = optional(bool, false)
      version   = optional(string)
      namespace = optional(string, "istio-system")
    }), {})
  })
  default = {}

  validation {
    condition = alltrue([
      for version in [
        var.addons.metrics_server.version,
        var.addons.nginx_ingress.version,
        var.addons.cert_manager.version,
        var.addons.argocd.version,
        var.addons.istio.version,
      ] : version == null || trimspace(version) != ""
      ]) && (
      length(var.addons.istio.namespace) <= 63 &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.addons.istio.namespace))
    )
    error_message = "Add-on versions must be null (latest) or non-empty chart versions, and the Istio namespace must be a valid Kubernetes namespace name."
  }
}