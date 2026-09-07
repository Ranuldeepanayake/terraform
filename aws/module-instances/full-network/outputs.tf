output "subnet_ids" {
  description = "Subnet IDs"
  value = module.subnets.subnet_ids
}

output "route_table_id" {
  description = "Route table ID"
  value = module.subnets.route_table_id
}

output "route_table_association_ids" {
  description = "Route table association IDs"
  value = module.subnets.route_table_association_ids
}