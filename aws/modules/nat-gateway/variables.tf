variable "name" {
  description = "Name tag for the NAT Gateway and associated Elastic IP."
  type        = string
}

variable "subnet_id" {
  description = "ID of the public subnet where the NAT Gateway will be created."
  type        = string
}

variable "connectivity_type" {
  description = "Connectivity type for the NAT Gateway. Usually 'public'."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.connectivity_type)
    error_message = "connectivity_type must be either 'public' or 'private'."
  }
}

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway used by the NAT Gateway's public subnet."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the NAT Gateway and Elastic IP."
  type        = map(string)
  default     = {}
}