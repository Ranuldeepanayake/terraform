###############################################################################
# RDS instance details and connection
###############################################################################

output "db_instance_id" {
  description = "Identifier of the PostgreSQL DB instance or Multi-AZ DB cluster."
  value       = module.postgres.db_instance_id
}

output "db_instance_arn" {
  description = "ARN of the PostgreSQL DB instance or Multi-AZ DB cluster."
  value       = module.postgres.db_instance_arn
}

output "db_instance_endpoint" {
  description = "Writer connection endpoint of the PostgreSQL DB instance or Multi-AZ DB cluster."
  value       = module.postgres.db_instance_endpoint
}

output "db_instance_address" {
  description = "DNS address of the PostgreSQL DB instance or Multi-AZ DB cluster writer endpoint."
  value       = module.postgres.db_instance_address
}

output "db_instance_port" {
  description = "PostgreSQL port for the DB instance or Multi-AZ DB cluster."
  value       = module.postgres.db_instance_port
}

output "db_cluster_identifier" {
  description = "Multi-AZ DB cluster identifier, or null when using DB instance mode."
  value       = module.postgres.db_cluster_identifier
}

output "db_cluster_reader_endpoint" {
  description = "Multi-AZ DB cluster reader endpoint, or null when using DB instance mode."
  value       = module.postgres.db_cluster_reader_endpoint
}

###############################################################################
# Credentials and database configuration
###############################################################################

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS-managed master password."
  value       = module.postgres.master_user_secret_arn
}

###############################################################################
# Monitoring and log exports
###############################################################################

output "monitoring_role_arn" {
  description = "IAM role used by RDS enhanced monitoring."
  value       = module.postgres.monitoring_role_arn
}

output "cloudwatch_log_group_names" {
  description = "CloudWatch log groups configured for PostgreSQL logs."
  value       = module.postgres.cloudwatch_log_group_names
}

output "parameter_group_name" {
  description = "Custom or supplied PostgreSQL parameter group name."
  value       = module.postgres.parameter_group_name
}

###############################################################################
# Replicas and alarms
###############################################################################

output "read_replica_endpoints" {
  description = "Map of read replica identifiers to connection endpoints."
  value       = module.postgres.read_replica_endpoints
}

output "cloudwatch_alarm_arns" {
  description = "Map of CloudWatch alarm names to their ARNs."
  value       = module.postgres.cloudwatch_alarm_arns
}

###############################################################################
# Snapshot export
###############################################################################

output "snapshot_export_task_id" {
  description = "RDS snapshot export task identifier, or null when not configured."
  value       = module.postgres.snapshot_export_task_id
}

output "snapshot_export_task_status" {
  description = "RDS snapshot export task status, or null when not configured."
  value       = module.postgres.snapshot_export_task_status
}

###############################################################################
# Networking and security groups
###############################################################################

output "db_subnet_group_name" {
  description = "Name of the RDS subnet group."
  value       = module.postgres.db_subnet_group_name
}

output "security_group_ids" {
  description = "Security group IDs associated with the PostgreSQL RDS instance."
  value       = module.postgres.security_group_ids
}