variable "role_name" {
  description = "Name of the IAM role granted to API Gateway for CloudWatch Logs write access"
  type        = string
  default     = "api-gateway-cloudwatch-logs"
}

variable "tags" {
  description = "Tags applied to the IAM role"
  type        = map(string)
  default     = {}
}
