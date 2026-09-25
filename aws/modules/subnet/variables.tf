variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnets" {
  description = "Public subnets to create"

  type = map(object({
    cidr_block                      = string
    ipv6_cidr_block                 = optional(string)
    assign_ipv6_address_on_creation = optional(bool, false)
    availability_zone               = string
    map_public_ip_on_launch         = bool
    route_table_id                  = string
    tags                            = map(string)
  }))
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}