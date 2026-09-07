locals {
  # Determine whether the module should create a security group. Security groups are only applicable to Interface VPC endpoints.
  create_endpoint_security_group = (var.vpc_endpoint_type == "Interface" && var.create_security_group)

  # Combine any existing security groups provided by the caller with the security group created by this module, if requested.
  endpoint_security_group_ids = concat(var.security_group_ids, local.create_endpoint_security_group ? [aws_security_group.endpoint[0].id] : [])
}