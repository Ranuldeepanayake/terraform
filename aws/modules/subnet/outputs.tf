output "subnet_ids" {
  description = "Subnet IDs"

  value = {
    for name, subnet in aws_subnet.subnet :
    name => subnet.id
  }
}

output "subnet_arns" {
  description = "Subnet ARNs"

  value = {
    for name, subnet in aws_subnet.subnet :
    name => subnet.arn
  }
}

output "route_table_id" {
  description = "Route table ID"

  value = aws_route_table.route_table.id
}

output "route_table_association_ids" {
  description = "Route table association IDs"

  value = {
    for name, association in aws_route_table_association.rta :
    name => association.id
  }
}