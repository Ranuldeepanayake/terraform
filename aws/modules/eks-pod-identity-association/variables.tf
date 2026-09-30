variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace containing the service account."
  type        = string
}

variable "service_account" {
  description = "Kubernetes service account name associated with the IAM role."
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN assumed by the service account through EKS Pod Identity."
  type        = string
}

variable "disable_session_tags" {
  description = "Whether to disable session tags for this association."
  type        = bool
  default     = false
}

variable "target_role_arn" {
  description = "Optional target role ARN for cross-account role assumption."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the Pod Identity association."
  type        = map(string)
  default     = {}
}
