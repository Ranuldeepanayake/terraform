resource "aws_vpc_endpoint" "this" {
  vpc_id            = var.vpc_id
  service_name      = var.service_name
  vpc_endpoint_type = var.vpc_endpoint_type

  # The below attributes are only applicable for interface endpoints.
  subnet_ids          = (var.vpc_endpoint_type == "Interface" ? var.subnet_ids : null)
  security_group_ids  = (var.vpc_endpoint_type == "Interface" ? local.endpoint_security_group_ids : null)
  private_dns_enabled = (var.vpc_endpoint_type == "Interface" ? var.private_dns_enabled : null)

  tags = merge(
    var.tags,
    {
      ResourceType = "VPCEndpoint"
    }
  )
}