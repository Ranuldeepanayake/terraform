output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.subnet.subnet_ids
}

output "route_table_id" {
  description = "Route table ID"
  value       = module.subnet.route_table_id
}

output "route_table_association_ids" {
  description = "Route table association IDs"
  value       = module.subnet.route_table_association_ids
}