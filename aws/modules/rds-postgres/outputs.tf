output "db_instance_id" {
  description = "The identifier of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "The DNS address of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "The PostgreSQL port used by the RDS instance."
  value       = aws_db_instance.this.port
}

output "db_instance_status" {
  description = "Current status of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.status
}

output "db_instance_resource_id" {
  description = "The AWS RDS resource ID of the PostgreSQL instance."
  value       = aws_db_instance.this.resource_id
}

output "db_subnet_group_name" {
  description = "Name of the RDS subnet group."
  value       = aws_db_subnet_group.this.name
}

output "db_subnet_group_arn" {
  description = "ARN of the RDS subnet group."
  value       = aws_db_subnet_group.this.arn
}

output "security_group_id" {
  description = "ID of the security group associated with the RDS instance. Returns the newly created security group ID when create_security_group is true, otherwise the first supplied security group ID."
  value = var.create_security_group ? (
  aws_security_group.this[0].id) : (length(var.security_group_ids) > 0 ? var.security_group_ids[0] : null)
}

output "security_group_ids" {
  description = "List of all security group IDs associated with the RDS instance."
  value       = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids
}