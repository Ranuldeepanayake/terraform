variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "service_name" {
  description = "AWS service name for the VPC endpoint."
  type        = string
}

variable "vpc_endpoint_type" {
  description = "VPC endpoint type."
  type        = string
  default     = "Interface"

  validation {
    condition     = contains(["Interface", "Gateway"], var.vpc_endpoint_type)
    error_message = "vpc_endpoint_type must be Interface or Gateway."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for an interface endpoint."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Existing security groups to attach to the endpoint."
  type        = list(string)
  default     = []
}

variable "private_dns_enabled" {
  description = "Enable private DNS for interface endpoints."
  type        = bool
  default     = true
}

variable "endpoint_name" {
  description = "Name of the VPC endpoint."
  type        = string
}

variable "create_security_group" {
  description = "Whether to create a security group for the endpoint."
  type        = bool
  default     = false
}

variable "security_group_name" {
  description = "Name of the security group to create."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group to create."
  type        = string
  default     = "Security group for VPC interface endpoint"
}

variable "security_group_ingress_rules" {
  description = "Ingress rules for the created security group."
  type = list(object({
    description                  = optional(string)
    from_port                    = optional(number, 443)
    to_port                      = optional(number, 443)
    protocol                     = optional(string, "tcp")
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = []
}

variable "security_group_egress_rules" {
  description = "Egress rules for the created security group."
  type = list(object({
    description                  = optional(string)
    from_port                    = optional(number, 0)
    to_port                      = optional(number, 0)
    protocol                     = optional(string, "-1")
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags for resources."
  type        = map(string)
  default     = {}
}