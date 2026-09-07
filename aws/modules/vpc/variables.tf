variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC"
  type        = string
}

variable "enable_dns_support" {
  description = "Enable DNS support"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
  default     = true
}

variable "assign_generated_ipv6_cidr_block" {
  description = "Assign AWS generated IPv6 cidr block"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}