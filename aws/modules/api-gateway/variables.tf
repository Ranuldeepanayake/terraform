variable "api_gateway_name" {
  description = "Name of the API Gateway HTTP API"
  type        = string
}

variable "protocol_type" {
  description = "API gateway protocol type"
  type        = string
  default     = "HTTP"
}

variable "ip_address_type" {
  description = "IP address type for the API Gateway"
  type        = string
  default     = "IPV4"

  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "ip_address_type must be IPV4 or DUALSTACK."
  }
}

variable "cors_configuration" {
  description = "CORS configuration for the API Gateway HTTP API"

  type = object({
    allow_headers = list(string)
    allow_methods = list(string)
    allow_origins = list(string)
  })

  default = {
    allow_headers = [
      "authorization",
      "content-type"
    ]

    allow_methods = [
      "GET",
      "POST",
      "PUT",
      "PATCH",
      "DELETE",
      "OPTIONS"
    ]

    allow_origins = ["*"]
  }
}

variable "integration_type" {
  description = "API gateway integration type"
  type        = string
  default     = "AWS_PROXY"
}

variable "lambda_functions" {
  description = "Existing Lambda functions keyed by logical name"
  type = map(object({
    arn = string
  }))
}

variable "integration_method" {
  description = "API gateway integration type"
  type        = string
  default     = "POST"
}

variable "payload_format_version" {
  description = "API gateway payload format version"
  type        = string
  default     = "2.0"
}

variable "integration_timeout_milliseconds" {
  description = "Maximum time API Gateway waits for an integration response, in milliseconds"
  type        = number
  default     = 30000

  validation {
    condition     = var.integration_timeout_milliseconds > 0
    error_message = "Integration timeout must be greater than 0 milliseconds."
  }
}

variable "routes" {
  description = "API Gateway routes mapped to existing Lambda functions"
  type = map(object({
    method        = string
    path          = string
    lambda        = string
    authorization = optional(string, "NONE")
    default       = optional(bool, false)
  }))

  validation {
    condition = length([
      for route in var.routes : route
      if route.default
    ]) == 1

    error_message = "Exactly one API route must have default = true."
  }
}

variable "logging" {
  type = object({
    enabled           = bool
    log_group_name    = string
    retention_in_days = number
  })

  default = {
    enabled           = true
    log_group_name    = ""
    retention_in_days = 30
  }
}

variable "throttling" {
  type = object({
    enabled     = bool
    rate_limit  = number
    burst_limit = number
  })

  default = {
    enabled     = false
    rate_limit  = 100
    burst_limit = 200
  }
}

variable "detailed_metrics_enabled" {
  type    = bool
  default = false
}

variable "custom_domain" {
  description = "Custom domain name for the API Gateway"
  type        = string
  default     = null
}

variable "endpoint_type" {
  description = "API Gateway custom domain endpoint type"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "EDGE"], var.endpoint_type)
    error_message = "endpoint_type must be either REGIONAL or EDGE."
  }
}

variable "security_policy" {
  description = "TLS security policy for the API Gateway custom domain"
  type        = string
  default     = "TLS_1_2"
}

variable "certificate_validation_method" {
  description = "ACM certificate validation method"
  type        = string
  default     = "DNS"

  validation {
    condition     = contains(["DNS", "EMAIL"], var.certificate_validation_method)
    error_message = "certificate_validation_method must be DNS or EMAIL."
  }
}

variable "certificate_subject_alternative_names" {
  description = "Additional domain names for the ACM certificate"
  type        = list(string)
  default     = []
}

variable "route53_hosted_zone_name" {
  description = "Route 53 hosted zone name used for ACM DNS validation."
  type        = string
}

variable "route53_private_zone" {
  description = "Whether the Route 53 hosted zone is private."
  type        = bool
  default     = false
}