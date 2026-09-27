output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = module.nat_gateway.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Public IPv4 address of the NAT Gateway."
  value       = module.nat_gateway.public_ip
}

output "nat_gateway_eip_id" {
  description = "Elastic IP allocation ID associated with the NAT Gateway."
  value       = module.nat_gateway.eip_id
}

output "associated_subnet_id" {
  description = "ID of the subnet where the NAT Gateway is deployed."
  value       = module.nat_gateway.associated_subnet_id
}

output "associated_internet_gateway_id" {
  description = "ID of the Internet Gateway associated with the NAT Gateway's public subnet."
  value       = module.nat_gateway.associated_internet_gateway_id
}