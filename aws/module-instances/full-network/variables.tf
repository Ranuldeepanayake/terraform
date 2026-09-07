variable "aws_region" {
  description = "AWS region"
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

variable "destination_cidr_block" {
  description = "Default route CIDR"
  type        = string
  default     = "0.0.0.0/0"
}

variable "route_table_tags" {
  description = "Route table tags"
  type    = map(string)
  default = {}
}