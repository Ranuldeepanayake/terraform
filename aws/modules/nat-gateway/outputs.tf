# ID of the NAT Gateway.
output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = aws_nat_gateway.this.id
}

# Allocation ID of the Elastic IP attached to the NAT Gateway.
output "allocation_id" {
  description = "Allocation ID of the Elastic IP attached to the NAT Gateway."
  value       = aws_eip.this.id
}

# Public IPv4 address assigned to the NAT Gateway.
output "public_ip" {
  description = "Public IPv4 address of the NAT Gateway."
  value       = aws_eip.this.public_ip
}

# ID of the Elastic IP resource.
output "eip_id" {
  description = "ID of the Elastic IP associated with the NAT Gateway."
  value       = aws_eip.this.id
}

output "associated_subnet_id" {
  description = "ID of the subnet where the NAT Gateway is deployed."
  value       = aws_nat_gateway.this.subnet_id
}

output "associated_internet_gateway_id" {
  description = "ID of the Internet Gateway associated with the NAT Gateway's public subnet."
  value       = data.aws_internet_gateway.this.id
}