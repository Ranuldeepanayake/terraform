# Subnet IDs in which to place the Lambda function. Empty means the Lambda is not configured for VPC access.
variable "vpc_subnet_ids" {
  description = "Subnet IDs in which to place the Lambda function. Empty means the Lambda is not configured for VPC access."
  type        = list(string)
  default     = []
}

# Name of the Lambda function.
variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

# Description of the Lambda function.
variable "description" {
  description = "Description of the Lambda function."
  type    = string
  default = "Lambda function"
}

# Runtime environment of the Lambda function.
variable "runtime" {
  description = "Runtime environment of the Lambda function."
  type    = string
  default = "nodejs24.x"
}

variable "handler" {
  type    = string
  default = "index.handler"
}

# Memory size in MB.
variable "memory_size" {
  type    = number
  default = 128
}

variable "timeout" {
  type    = number
  default = 10
}

# Ephememeral storage size for processing.
variable "ephemeral_storage_size" {
  description = "Lambda function /tmp storage size in MB."
  type        = number
  default     = 512

  validation {
    condition     = var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240
    error_message = "Must be between 512 and 10240 MB."
  }
}

# Environment variables of the Lambda function.
variable "environment_variables" {
  description = "Environment variables of the Lambda function."
  type    = map(string)
  default = {}
}

# Whether to enable asynchronous Lambda invocation.
variable "create_function_event_invoke_config" {
  description = "Whether to enable asynchronous Lambda invocation."
  type        = bool
  default     = false
}

# Maximum age of an asynchronous event before Lambda discards it.
variable "maximum_event_age_in_seconds" {
  description = "Maximum age of an asynchronous event before Lambda discards it."
  type        = number
  default     = 3600

  validation {
    condition     = var.maximum_event_age_in_seconds >= 60 && var.maximum_event_age_in_seconds <= 86400
    error_message = "Must be between 60 and 86400 seconds."
  }
}

# Maximum number of retries for asynchronous Lambda invocations
variable "maximum_retry_attempts" {
  description = "Maximum number of retries for asynchronous Lambda invocations."
  type        = number
  default     = 2

  validation {
    condition     = var.maximum_retry_attempts >= 0 && var.maximum_retry_attempts <= 2
    error_message = "Must be between 0 and 2."
  }
}

# Create a new role for the lambda function.
variable "create_role" {
  description = "Create a new role for the lambda function."
  type    = bool
  default = true
}

# Specify existing IAM role ARN if create_role is false. If create_role is false, the module will use an existing IAM role for the Lambda function.
variable "lambda_role_arn" {
  description = "ARN of an existing IAM role for the lambda function."
  type    = string
  default = null
}

# Specify IAM role name if create_role is true. If create_role is true, the module will create a new IAM role for the Lambda function with this name.
variable "lambda_role_name" {
  description = "Name of the new IAM role to create."
  type        = string
  default     = null
}

# Optional inline custom IAM policy.
variable "custom_policy" {
  description = "Optional IAM policy document in JSON format. The module creates and attaches this policy to the Lambda execution role."
  type        = string
  default     = null
}

# Optional list of existing custom policies.
variable "custom_policy_arns" {
  description = "Optional list of existing IAM policy ARNs to attach to the Lambda execution role."
  type        = list(string)
  default     = []
}

# Create an endpoint URL the lambda function.
variable "create_function_url" {
  description = "Create an endpoint URL the lambda function."
  type    = bool
  default = false
}

# CORS configuration for the Lambda function URL. If null, no CORS configuration is applied.
variable "cors" {
  description = "CORS configuration for the Lambda function URL."
  type = object({
    allow_origins = list(string)
    allow_methods = list(string)
    allow_headers = list(string)
  })
  default = null
}

variable "authorization_type" {
  type    = string
  default = "NONE" # or "AWS_IAM"
}

# CloudWatch log retention in days.
variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 7
}

# Whether to create a dedicated security group for the Lambda function.
variable "create_security_group" {
  description = "Whether to create a dedicated security group for the Lambda function."
  type        = bool
  default     = false
}

# Specify existing security group IDs if create_security_group is false. If create_security_group is true, the module will create a new security group for the Lambda function.
variable "vpc_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Existing security group IDs to associate with the Lambda function."
}

# Name of the new security group to create.
variable "security_group_name" {
  type        = string
  default     = null
  description = "Name of the new security group to create."
}

# Description of the security group to create.
variable "security_group_description" {
  type        = string
  default     = null
  description = "Description of the security group to create."
}

# Ingress rules are only needed for a VPC based resource to directly communicate with the Lambda function. Lambda normally does not need inbound rules,
# since the invoke URL allows requests.
variable "security_group_ingress_rules" {
  description = "Ingress rules for the Lambda security group."
  type = map(object({
    description                  = optional(string)
    from_port                    = number
    to_port                      = number
    protocol                     = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default     = {}

}

# Create a security group with an egress rule that allows all outbound traffic by default for communication with VPC resources (not required by the invoke URL).
# Eventhough AWS offers a default egress rule that allows all outbound traffic, it is better to explicitly define it in the security group to avoid any confusion or misconfiguration.
variable "security_group_egress_rules" {
  description = "Egress rules for the Lambda security group."
  type = map(object({
    description                  = optional(string)
    from_port                    = number
    to_port                      = number
    protocol                     = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
  }))

  default = {
    all_ipv4 = {
      description = "Allow all outbound IPv4 traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    },
    all_ipv6 = {
      description = "Allow all outbound IPv6 traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_ipv6   = "::/0"
    }
  }
}

# Whether to use inline code.
variable "use_inline_code" {
  description = "Whether to use inline code."
  type    = bool
  default = true

  validation {
    condition = ((var.use_inline_code && var.inline_code != null) || (!var.use_inline_code && var.source_path != null))
    error_message = "You must provide either inline_code (when use_inline_code = true) or source_path (when false)."
  }
}

# Path to an existing ZIP file containing the Lambda function code. This is used when use_inline_code = false.
variable "source_path" {
  description = "Path to ZIP file if not using inline code"
  type        = string
  default     = null
}

# Inline code for the Lambda function. This is used when use_inline_code = true.
variable "inline_code" {
  description = "Inline code for Lambda (optional, required if use_inline_code = true)"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
