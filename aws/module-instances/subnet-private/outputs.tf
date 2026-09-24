output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.subnet.subnet_ids
}

output "subnet_arns" {
  description = "Subnet ARNs"
  value       = module.subnet.subnet_arns
}

output "route_table_association_ids" {
  description = "Route table association IDs"
  value       = module.subnet.route_table_association_ids
}