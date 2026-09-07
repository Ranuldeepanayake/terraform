output "id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "arn" {
  description = "VPC ARN"
  value       = aws_vpc.this.arn
}

output "cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "default_route_table_id" {
  description = "Default route table ID"
  value       = aws_vpc.this.default_route_table_id
}

output "default_network_acl_id" {
  description = "Default Network ACL ID"
  value       = aws_vpc.this.default_network_acl_id
}

output "default_security_group_id" {
  description = "Default Security Group ID"
  value       = aws_vpc.this.default_security_group_id
}