output "vpc_endpoint_id" {
  description = "The ID of the VPC endpoint."
  value       = aws_vpc_endpoint.this.id
}

output "vpc_endpoint_arn" {
  description = "The ARN of the VPC endpoint."
  value       = aws_vpc_endpoint.this.arn
}

output "vpc_endpoint_type" {
  description = "The type of the VPC endpoint, such as Interface or Gateway."
  value       = aws_vpc_endpoint.this.vpc_endpoint_type
}

output "vpc_id" {
  description = "The ID of the VPC in which the VPC endpoint is deployed."
  value       = aws_vpc_endpoint.this.vpc_id
}

output "service_name" {
  description = "The AWS service name associated with the VPC endpoint."
  value       = aws_vpc_endpoint.this.service_name
}

output "state" {
  description = "The current state of the VPC endpoint, such as pending, available, deleting, or deleted."
  value       = aws_vpc_endpoint.this.state
}

output "subnet_ids" {
  description = "The IDs of the subnets associated with the VPC endpoint. Applicable to interface endpoints."
  value       = aws_vpc_endpoint.this.subnet_ids
}

output "security_group_ids" {
  description = "The IDs of the security groups associated with the VPC endpoint. Applicable to interface endpoints."
  value       = aws_vpc_endpoint.this.security_group_ids
}

output "private_dns_enabled" {
  description = "Whether private DNS is enabled for the VPC endpoint."
  value       = aws_vpc_endpoint.this.private_dns_enabled
}

output "dns_entries" {
  description = "DNS entries associated with the VPC endpoint. Applicable to interface endpoints."
  value       = aws_vpc_endpoint.this.dns_entry
}

output "network_interface_ids" {
  description = "The IDs of the network interfaces created for the VPC endpoint. Applicable to interface endpoints."
  value       = aws_vpc_endpoint.this.network_interface_ids
}

output "created_security_group_id" {
  description = "The ID of the security group created by this module, or null when an existing security group is used or security group creation is disabled."
  value       = (local.create_endpoint_security_group ? aws_security_group.endpoint[0].id : null)
}

output "created_security_group_name" {
  description = "The name of the security group created by this module, or null when the module does not create a security group."
  value       = (local.create_endpoint_security_group ? aws_security_group.endpoint[0].name : null)
}

output "created_security_group_arn" {
  description = "The ARN of the security group created by this module, or null when the module does not create a security group."
  value       = (local.create_endpoint_security_group ? aws_security_group.endpoint[0].arn : null)
}

output "endpoint_security_group_ids" {
  description = "All security group IDs associated with the VPC endpoint, including both existing security groups and any security group created by this module."
  value       = local.endpoint_security_group_ids
}

output "endpoint_name" {
  description = "The logical name assigned to the VPC endpoint by the caller."
  value       = var.endpoint_name
}