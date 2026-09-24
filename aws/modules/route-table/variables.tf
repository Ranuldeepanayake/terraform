variable "vpc_id" {
  description = "ID of the existing VPC in which the route table will be created."
  type        = string
}

variable "route_table_name" {
  description = "Name of the route table. This is applied using the AWS Name tag."
  type        = string
}

variable "routes" {
  description = <<-EOT
    Routes to create in the route table.

    Each route is identified by a unique map key and must contain exactly
    one destination and exactly one target.

    Supported destinations:
      - cidr_block
      - ipv6_cidr_block
      - prefix_list_id

    Supported targets:
      - gateway_id
      - nat_gateway_id
      - network_interface_id
      - transit_gateway_id
      - vpc_peering_connection_id
      - egress_only_gateway_id
      - local_gateway_id
      - carrier_gateway_id
      - core_network_arn
  EOT

  type = map(object({
    # -------------------------------------------------------------------------
    # Destination
    #
    # Exactly ONE of these must be specified.
    # -------------------------------------------------------------------------

    cidr_block      = optional(string)
    ipv6_cidr_block = optional(string)
    prefix_list_id  = optional(string)

    # -------------------------------------------------------------------------
    # Target
    #
    # Exactly ONE of these must be specified.
    # -------------------------------------------------------------------------

    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    network_interface_id      = optional(string)
    transit_gateway_id        = optional(string)
    vpc_peering_connection_id = optional(string)
    egress_only_gateway_id    = optional(string)
    local_gateway_id          = optional(string)
    carrier_gateway_id        = optional(string)
    core_network_arn          = optional(string)
  }))

  default = {}

  # ---------------------------------------------------------------------------
  # Validate each route.
  #
  # Terraform evaluates this validation once for every route in the map.
  # ---------------------------------------------------------------------------
  validation {
    condition = alltrue([
      for route_name, route in var.routes : (
        # ---------------------------------------------------------------------
        # Exactly one destination must be specified.
        # ---------------------------------------------------------------------
        (
          (route.cidr_block != null ? 1 : 0) +
          (route.ipv6_cidr_block != null ? 1 : 0) +
          (route.prefix_list_id != null ? 1 : 0)
        ) == 1

        &&

        # ---------------------------------------------------------------------
        # Exactly one target must be specified.
        # ---------------------------------------------------------------------
        (
          (route.gateway_id != null ? 1 : 0) +
          (route.nat_gateway_id != null ? 1 : 0) +
          (route.network_interface_id != null ? 1 : 0) +
          (route.transit_gateway_id != null ? 1 : 0) +
          (route.vpc_peering_connection_id != null ? 1 : 0) +
          (route.egress_only_gateway_id != null ? 1 : 0) +
          (route.local_gateway_id != null ? 1 : 0) +
          (route.carrier_gateway_id != null ? 1 : 0) +
          (route.core_network_arn != null ? 1 : 0)
        ) == 1
      )
    ])

    error_message = "Each route must specify exactly one destination (cidr_block, ipv6_cidr_block, or prefix_list_id) and exactly one target (gateway_id, nat_gateway_id, network_interface_id, transit_gateway_id, vpc_peering_connection_id, egress_only_gateway_id, local_gateway_id, carrier_gateway_id, or core_network_arn)."
  }
}

variable "tags" {
  description = "Additional tags to apply to the route table."
  type        = map(string)
  default     = {}
}