variable "subnets" {
  description = "Public subnets to create"

  type = map(object({
    name              = string
    cidr_block        = string
    availability_zone = string
    map_public_ip_on_launch = bool
    tags              = map(string)
  }))
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "internet_gateway_id" {
  description = "Internet Gateway ID"
  type        = string
}

variable "default_route" {
  description = "Default route"
  type        = string
}

variable "route_table_tags" {
  description = "Route table tags"
  type    = map(string)
  default = {}
}