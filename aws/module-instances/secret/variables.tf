variable "aws_region" {
  type        = string
  description = "AWS region for operations"
  default     = "ap-southeast-1"
}

# Pass in a set of secret values. The caller will encode it to json.
variable "secret_values" {
  type      = map(string)
  sensitive = true
}