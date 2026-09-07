output "id" {
  description = "VPC endpoint ID."
  value       = aws_vpc_endpoint.this.id
}

output "arn" {
  description = "VPC endpoint ARN."
  value       = aws_vpc_endpoint.this.arn
}

output "security_group_id" {
  description = "ID of the security group created by the module, if any."
  value = (
    local.create_endpoint_security_group
    ? aws_security_group.endpoint[0].id
    : null
  )
}

output "network_interface_ids" {
  description = "Network interface IDs for the interface endpoint."
  value       = aws_vpc_endpoint.this.network_interface_ids
}

output "dns_entries" {
  description = "DNS entries for the interface endpoint."
  value       = aws_vpc_endpoint.this.dns_entry
}