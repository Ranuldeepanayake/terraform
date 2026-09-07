variable "name" {
  description = "Name of the Secrets Manager secret."
  type        = string
}

variable "description" {
  description = "Description of the secret."
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key ARN, key ID, or alias used to encrypt the secret. If null, AWS uses aws/secretsmanager."
  type        = string
  default     = null
}

variable "secret_string" {
  description = "Secret value to store."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to the secret."
  type        = map(string)
  default     = {}
}