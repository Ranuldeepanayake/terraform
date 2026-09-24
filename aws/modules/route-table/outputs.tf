output "route_table_name" {
  description = "Name of the created route table."
  value       = var.route_table_name
}

output "route_table_id" {
  description = "ID of the created route table."
  value       = aws_route_table.this.id
}

output "route_table_arn" {
  description = "ARN of the created route table."
  value       = aws_route_table.this.arn
}

output "route_ids" {
  description = "Map containing the IDs of the routes created in the route table."
  value = {
    for key, route in aws_route.this :
    key => route.id
  }
}