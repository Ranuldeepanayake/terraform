output "vpc_endpoint_id" {
  description = "The ID of the VPC endpoint."
  value       = module.vpc_endpoint.vpc_endpoint_id
}

output "vpc_endpoint_arn" {
  description = "The ARN of the VPC endpoint."
  value       = module.vpc_endpoint.vpc_endpoint_arn
}

output "vpc_endpoint_type" {
  description = "The type of the VPC endpoint, such as Interface or Gateway."
  value       = module.vpc_endpoint.vpc_endpoint_type
}

output "vpc_id" {
  description = "The ID of the VPC in which the VPC endpoint is deployed."
  value       = module.vpc_endpoint.vpc_id
}

output "service_name" {
  description = "The AWS service name associated with the VPC endpoint."
  value       = module.vpc_endpoint.service_name
}

output "state" {
  description = "The current state of the VPC endpoint."
  value       = module.vpc_endpoint.state
}

output "subnet_ids" {
  description = "The IDs of the subnets associated with the VPC endpoint."
  value       = module.vpc_endpoint.subnet_ids
}

output "security_group_ids" {
  description = "The IDs of the security groups associated with the VPC endpoint."
  value       = module.vpc_endpoint.security_group_ids
}

output "endpoint_security_group_ids" {
  description = "All security group IDs associated with the VPC endpoint, including any security group created by the module."
  value       = module.vpc_endpoint.endpoint_security_group_ids
}

output "private_dns_enabled" {
  description = "Whether private DNS is enabled for the VPC endpoint."
  value       = module.vpc_endpoint.private_dns_enabled
}

output "dns_entries" {
  description = "DNS entries associated with the VPC endpoint."
  value       = module.vpc_endpoint.dns_entries
}

output "network_interface_ids" {
  description = "The network interface IDs associated with the VPC endpoint."
  value       = module.vpc_endpoint.network_interface_ids
}

output "created_security_group_id" {
  description = "The ID of the security group created by the module, or null if an existing security group is used."
  value       = module.vpc_endpoint.created_security_group_id
}

output "created_security_group_name" {
  description = "The actual name of the security group created by the module, or null if a security group was not created."
  value       = module.vpc_endpoint.created_security_group_name
}

output "created_security_group_arn" {
  description = "The ARN of the security group created by the module, or null if a security group was not created."
  value       = module.vpc_endpoint.created_security_group_arn
}

output "endpoint_name" {
  description = "The logical name assigned to the VPC endpoint."
  value       = module.vpc_endpoint.endpoint_name
}