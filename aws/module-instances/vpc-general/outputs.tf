output "id" {
  description = "VPC ID"
  value       = module.vpc.id
}

output "arn" {
  description = "VPC ARN"
  value       = module.vpc.arn
}

output "cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.cidr_block
}

output "default_route_table_id" {
  description = "Default route table ID"
  value       = module.vpc.default_route_table_id
}

output "default_network_acl_id" {
  description = "Default Network ACL ID"
  value       = module.vpc.default_network_acl_id
}

output "default_security_group_id" {
  description = "Default Security Group ID"
  value       = module.vpc.default_security_group_id
}