# ---------------------------------------
# Input Variables for Existing Resources
# ---------------------------------------
variable "resource_name" {
  description = "A name to easily identify a resource"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "IDs of existing subnets"
  type        = list(string)
}

variable "instance_id" {
  description = "IDs of the instances included in the target group"
  type        = list(string)
}

variable "ip_stack" {
  description = "Use IPv4,IPv6 or dual stack"
  type        = string
}

variable "enable_ipv4" {
  description = "Enable IPv4 for the EC2 hosts"
  type        = bool
}