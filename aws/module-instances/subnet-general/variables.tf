variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "internet_gateway_id" {
  description = "Internet gateway ID"
  type        = string
}

variable "subnets" {
  description = "Map of subnets"

  type = map(object({
    name                    = string
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
    tags                    = map(string)
  }))
}

variable "default_route" {
  description = "Default route CIDR"
  type        = string
  default     = "0.0.0.0/0"
}

variable "route_table_tags" {
  description = "Route table tags"
  type        = map(string)
  default     = {}
}