output "route_table_name" {
  description = "Name of the created route table."
  value       = module.route_table.route_table_name
}

output "route_table_id" {
  description = "ID of the created route table."
  value       = module.route_table.route_table_id
}

output "route_table_arn" {
  description = "ARN of the created route table."
  value       = module.route_table.route_table_arn
}

output "route_ids" {
  description = "Map containing the IDs of the routes created in the route table."
  value       = module.route_table.route_ids
}