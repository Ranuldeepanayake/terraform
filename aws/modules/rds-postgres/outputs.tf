###############################################################################
# RDS instance details and connection
###############################################################################

output "db_instance_id" {
  description = "The RDS DB instance identifier, or DB cluster identifier when deployment_mode is multi_az_cluster."
  value       = var.deployment_mode == "db_instance" ? aws_db_instance.this[0].id : aws_rds_cluster.multi_az[0].cluster_identifier
}

output "db_instance_arn" {
  description = "The RDS DB instance ARN, or DB cluster ARN when deployment_mode is multi_az_cluster."
  value       = var.deployment_mode == "db_instance" ? aws_db_instance.this[0].arn : aws_rds_cluster.multi_az[0].arn
}

output "db_instance_endpoint" {
  description = "The writer connection endpoint of the DB instance or Multi-AZ DB cluster."
  value = var.deployment_mode == "db_instance" ? aws_db_instance.this[0].endpoint : (
    "${aws_rds_cluster.multi_az[0].endpoint}:${aws_rds_cluster.multi_az[0].port}"
  )
}

output "db_instance_address" {
  description = "The DNS address of the DB instance or Multi-AZ DB cluster writer endpoint."
  value       = var.deployment_mode == "db_instance" ? aws_db_instance.this[0].address : aws_rds_cluster.multi_az[0].endpoint
}

output "db_instance_port" {
  description = "The PostgreSQL port used by the DB instance or Multi-AZ DB cluster."
  value       = var.deployment_mode == "db_instance" ? aws_db_instance.this[0].port : aws_rds_cluster.multi_az[0].port
}

output "db_instance_status" {
  description = "Current DB instance status, or null for Multi-AZ DB cluster mode."
  value       = var.deployment_mode == "db_instance" ? aws_db_instance.this[0].status : null
}

output "db_instance_resource_id" {
  description = "The AWS RDS resource ID of the DB instance or cluster."
  value       = var.deployment_mode == "db_instance" ? aws_db_instance.this[0].resource_id : aws_rds_cluster.multi_az[0].cluster_resource_id
}

output "db_cluster_identifier" {
  description = "The Multi-AZ DB cluster identifier, or null when using DB instance mode."
  value       = var.deployment_mode == "multi_az_cluster" ? aws_rds_cluster.multi_az[0].cluster_identifier : null
}

output "db_cluster_reader_endpoint" {
  description = "The reader endpoint for Multi-AZ DB cluster mode, or null when using DB instance mode."
  value       = var.deployment_mode == "multi_az_cluster" ? aws_rds_cluster.multi_az[0].reader_endpoint : null
}

###############################################################################
# Credentials and database configuration
###############################################################################

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS-managed master password, or null when a password is user supplied."
  value = try(
    var.deployment_mode == "db_instance" ? aws_db_instance.this[0].master_user_secret[0].secret_arn : aws_rds_cluster.multi_az[0].master_user_secret[0].secret_arn,
    null
  )
}

output "parameter_group_name" {
  description = "Name of the custom or supplied DB parameter group, or null when the default group is used."
  value       = local.effective_parameter_group_name
}

###############################################################################
# Monitoring and log exports
###############################################################################

output "monitoring_role_arn" {
  description = "IAM role ARN used by RDS enhanced monitoring, or null when monitoring is disabled."
  value       = local.monitoring_role_arn
}

output "cloudwatch_log_group_names" {
  description = "Names of CloudWatch log groups configured for RDS log exports."
  value       = [for group in aws_cloudwatch_log_group.rds : group.name]
}

###############################################################################
# Replicas and alarms
###############################################################################

output "read_replica_endpoints" {
  description = "Map of read replica identifiers to their connection endpoints."
  value       = { for identifier, replica in aws_db_instance.read_replica : identifier => replica.endpoint }
}

output "cloudwatch_alarm_arns" {
  description = "Map of configured CloudWatch alarm names to their ARNs."
  value       = { for name, alarm in aws_cloudwatch_metric_alarm.rds : name => alarm.arn }
}

###############################################################################
# Snapshot export
###############################################################################

output "snapshot_export_task_id" {
  description = "Identifier of the configured RDS snapshot export task, or null when export is not configured."
  value       = try(aws_rds_export_task.snapshot[0].id, null)
}

output "snapshot_export_task_status" {
  description = "Current status of the RDS snapshot export task, or null when export is not configured."
  value       = try(aws_rds_export_task.snapshot[0].status, null)
}

###############################################################################
# Networking
###############################################################################

output "db_subnet_group_name" {
  description = "Name of the RDS subnet group."
  value       = aws_db_subnet_group.this.name
}

output "db_subnet_group_arn" {
  description = "ARN of the RDS subnet group."
  value       = aws_db_subnet_group.this.arn
}

###############################################################################
# Security groups
###############################################################################

output "security_group_id" {
  description = "ID of the security group associated with the RDS instance. Returns the newly created security group ID when create_security_group is true, otherwise the first supplied security group ID."
  value = var.create_security_group ? (
  aws_security_group.this[0].id) : (length(var.security_group_ids) > 0 ? var.security_group_ids[0] : null)
}

output "security_group_ids" {
  description = "List of all security group IDs associated with the RDS instance."
  value       = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids
}