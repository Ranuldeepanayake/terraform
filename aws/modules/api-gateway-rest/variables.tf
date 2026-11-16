variable "api_gateway_name" {
  description = "Name of the REST API"
  type        = string
}

variable "description" {
  description = "Description of the REST API"
  type        = string
  default     = null
}

variable "endpoint_type" {
  description = "API endpoint type"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "EDGE", "PRIVATE"], var.endpoint_type)
    error_message = "endpoint_type must be REGIONAL, EDGE, or PRIVATE."
  }
}

variable "cors_configuration" {
  description = "CORS configuration. When set, OPTIONS methods with MOCK integrations are added to every resource path. Lambda responses must still include CORS headers for non-preflight requests."
  type = object({
    allow_headers = list(string)
    allow_methods = list(string)
    allow_origins = list(string)
  })
  default = null
}

variable "integration_type" {
  description = "Lambda integration type"
  type        = string
  default     = "AWS_PROXY"
}

variable "integration_method" {
  description = "HTTP method used when invoking the Lambda integration"
  type        = string
  default     = "POST"
}

variable "integration_timeout_milliseconds" {
  description = "Maximum time API Gateway waits for an integration response, in milliseconds. REST API maximum is 29000."
  type        = number
  default     = 29000

  validation {
    condition     = var.integration_timeout_milliseconds > 0 && var.integration_timeout_milliseconds <= 29000
    error_message = "Integration timeout must be between 1 and 29000 milliseconds."
  }
}

variable "lambda_functions" {
  description = "Existing Lambda functions keyed by logical name"
  type = map(object({
    arn = string
  }))
}

variable "routes" {
  description = "API Gateway routes mapped to Lambda functions. Each route maps to one method on one resource path."
  type = map(object({
    method           = string
    path             = string
    lambda           = string
    authorization    = optional(string, "NONE")
    api_key_required = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for r in var.routes : length(split("/", trimprefix(r.path, "/"))) <= 4
    ])
    error_message = "Route paths support a maximum depth of 4 segments (e.g. /a/b/c/d)."
  }
}

variable "stages" {
  description = "API Gateway stages. All stages share the same deployment, which is redeployed when deployment_trigger changes."
  type = map(object({
    description               = optional(string)
    stage_variables           = optional(map(string), {})
    tags                      = optional(map(string), {})
    detailed_metrics_enabled  = optional(bool, false)
    logging_level             = optional(string)
    data_trace_enabled        = optional(bool, false)
    xray_tracing_enabled      = optional(bool, false)
    custom_domain_mapping_key = optional(string)
    logging = optional(object({
      enabled           = optional(bool)
      log_group_name    = optional(string)
      retention_in_days = optional(number)
      format            = optional(string)
    }), {})
    throttling = optional(object({
      enabled     = optional(bool)
      rate_limit  = optional(number)
      burst_limit = optional(number)
    }), {})
    route_settings = optional(map(object({
      data_trace_enabled       = optional(bool)
      detailed_metrics_enabled = optional(bool)
      logging_level            = optional(string)
      throttling_rate_limit    = optional(number)
      throttling_burst_limit   = optional(number)
    })), {})
  }))

  default = {
    prod = {}
  }

  validation {
    condition     = length(var.stages) > 0
    error_message = "Configure at least one API Gateway stage."
  }
}

variable "deployment_trigger" {
  description = "Change this string to force a new API deployment across all stages (e.g. 'v1', 'v2')."
  type        = string
}

variable "usage_plans" {
  description = "Usage plans keyed by logical name. An API key is created per plan when any route has api_key_required = true."
  type = map(object({
    description = optional(string)
    stages      = list(string)
    throttle = optional(object({
      rate_limit  = optional(number)
      burst_limit = optional(number)
    }))
    quota = optional(object({
      limit  = number
      period = string
    }))
  }))
  default = {}
}

variable "custom_domain" {
  description = "Custom domain name for the API Gateway"
  type        = string
  default     = null
}

variable "endpoint_type_custom_domain" {
  description = "Endpoint type for the custom domain (REGIONAL or EDGE)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "EDGE"], var.endpoint_type_custom_domain)
    error_message = "endpoint_type_custom_domain must be REGIONAL or EDGE."
  }
}

variable "security_policy" {
  description = "TLS security policy for the custom domain"
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
  description = "Route 53 hosted zone name used for ACM DNS validation"
  type        = string
  default     = null
}

variable "route53_private_zone" {
  description = "Whether the Route 53 hosted zone is private"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Default tags applied to all taggable resources"
  type        = map(string)
  default     = {}
}
