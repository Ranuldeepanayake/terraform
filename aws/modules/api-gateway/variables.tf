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

variable "stages" {
  description = "API Gateway stages keyed by stage name. Each stage can configure its own deployment, observability, and domain mapping."
  type = map(object({
    auto_deploy               = optional(bool, true)
    deployment_trigger        = optional(string)
    description               = optional(string)
    stage_variables           = optional(map(string), {})
    tags                      = optional(map(string), {})
    detailed_metrics_enabled  = optional(bool)
    logging_level             = optional(string)
    data_trace_enabled        = optional(bool)
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
    "$default" = {}
  }

  validation {
    condition     = length(var.stages) > 0
    error_message = "Configure at least one API Gateway stage."
  }

  validation {
    condition = alltrue([
      for stage in values(var.stages) :
      stage.auto_deploy || try(trimspace(stage.deployment_trigger) != "", false)
    ])
    error_message = "Stages with auto_deploy = false must set a non-empty deployment_trigger. Change the trigger to publish a new deployment."
  }

  validation {
    condition = length([
      for stage in values(var.stages) : stage.custom_domain_mapping_key
      if stage.custom_domain_mapping_key != null
      ]) == length(distinct([
        for stage in values(var.stages) : stage.custom_domain_mapping_key
        if stage.custom_domain_mapping_key != null
      ])) && alltrue([
      for stage in values(var.stages) :
      stage.custom_domain_mapping_key == null || try(
        stage.custom_domain_mapping_key == "" ||
        (
          trimspace(stage.custom_domain_mapping_key) != "" &&
          !startswith(stage.custom_domain_mapping_key, "/")
        ),
        false
      )
      ]) && alltrue([
      for stage in values(var.stages) :
      stage.custom_domain_mapping_key == null || var.custom_domain != null
    ])
    error_message = "Custom-domain mapping keys must be unique path prefixes without a leading slash (use an empty key for the root mapping), and require custom_domain to be set."
  }
}

variable "logging" {
  description = "Legacy defaults for stage access logging. Stage-level logging settings override these values."
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
  description = "Legacy defaults for stage throttling. Stage-level throttling settings override these values."
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
  description = "Legacy default for stage detailed metrics. Stage-level settings override this value."
  type        = bool
  default     = false
}

variable "custom_domain" {
  description = "Custom domain name for the API Gateway"
  type        = string
  default     = null
}

variable "custom_domain_stage" {
  description = "Stage exposed through the custom domain mapping."
  type        = string
  default     = "$default"

  validation {
    condition = var.custom_domain == null || anytrue([
      for stage in values(var.stages) : stage.custom_domain_mapping_key != null
    ]) || contains(keys(var.stages), var.custom_domain_stage)
    error_message = "custom_domain_stage must match a configured stage when no stage-specific custom-domain mapping key is set."
  }
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