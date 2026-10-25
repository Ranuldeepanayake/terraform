# =============================================================================
# Deployment Mode
# =============================================================================

output "deployment_mode" {
  description = "The deployment mode of the cache (provisioned or serverless)."
  value       = var.deployment_mode
}

# =============================================================================
# Cache Details and Connection
# =============================================================================

output "cluster_id" {
  description = "The ElastiCache Valkey cluster/cache identifier."
  value       = var.cluster_id
}

output "cluster_arn" {
  description = "The ARN of the ElastiCache Valkey cache."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].arn : aws_elasticache_serverless_cache.serverless[0].arn
}

output "engine" {
  description = "The cache engine used (valkey)."
  value       = "valkey"
}

output "engine_version" {
  description = "The Valkey engine version in use."
  value       = var.engine_version
}

# =============================================================================
# Connection Information
# =============================================================================

output "cluster_address" {
  description = "The DNS hostname of the cache endpoint."
  value = var.deployment_mode == "provisioned" ? (
    aws_elasticache_replication_group.provisioned[0].primary_endpoint_address
  ) : (
    aws_elasticache_serverless_cache.serverless[0].endpoint[0].address
  )
}

output "cluster_port" {
  description = "The port of the cache endpoint."
  value = var.deployment_mode == "provisioned" ? (
    var.port
  ) : (
    aws_elasticache_serverless_cache.serverless[0].endpoint[0].port
  )
}

output "primary_endpoint" {
  description = "The primary endpoint of the cache in 'address:port' format."
  value = var.deployment_mode == "provisioned" ? (
    "${aws_elasticache_replication_group.provisioned[0].primary_endpoint_address}:${var.port}"
  ) : (
    "${aws_elasticache_serverless_cache.serverless[0].endpoint[0].address}:${aws_elasticache_serverless_cache.serverless[0].endpoint[0].port}"
  )
}

output "cache_nodes" {
  description = "Map of cache node IDs to their endpoints. Only available for provisioned mode."
  value = var.deployment_mode == "provisioned" ? (
    {
      for node in aws_elasticache_replication_group.provisioned[0].member_clusters :
      node => "${node}-node"
    }
  ) : null
}

# =============================================================================
# Cluster Configuration (Provisioned)
# =============================================================================

output "node_type" {
  description = "The compute and memory capacity of the nodes. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].node_type : null
}

output "num_cache_nodes" {
  description = "The number of cache nodes in the cluster. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].num_cache_clusters : null
}

output "automatic_failover_enabled" {
  description = "Whether automatic failover is enabled. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].automatic_failover_enabled : null
}

output "multi_az_enabled" {
  description = "Whether Multi-AZ is enabled. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].multi_az_enabled : null
}

output "availability_zone" {
  description = "The Availability Zone of the primary cache node. Only for provisioned mode."
  value       = null
}

# =============================================================================
# Serverless Configuration
# =============================================================================

output "serverless_cache_size" {
  description = "The maximum data storage size for the serverless cache in GB. Only for serverless mode."
  value       = var.deployment_mode == "serverless" ? var.serverless_cache_size : null
}

# =============================================================================
# Security Configuration
# =============================================================================

output "security_group_id" {
  description = "The ID of the security group created for the cache. Returns null if create_security_group is false."
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_ids" {
  description = "List of security group IDs associated with the cache."
  value       = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids
}

output "at_rest_encryption_enabled" {
  description = "Whether at-rest encryption is enabled."
  value       = var.at_rest_encryption_enabled
}

output "transit_encryption_enabled" {
  description = "Whether transit encryption is enabled. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].transit_encryption_enabled : null
}

# =============================================================================
# Parameter and Subnet Group Details
# =============================================================================

output "parameter_group_name" {
  description = "The name of the parameter group associated with the cluster. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].parameter_group_name : null
}

output "subnet_group_name" {
  description = "The name of the subnet group associated with the cluster. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].subnet_group_name : null
}

output "subnet_group_id" {
  description = "The ElastiCache subnet group ID. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_subnet_group.this.id : null
}

# =============================================================================
# Snapshot and Backup Configuration
# =============================================================================

output "snapshot_retention_limit" {
  description = "Number of days for which automatic snapshots are retained. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].snapshot_retention_limit : null
}

output "snapshot_window" {
  description = "The daily time window for automatic snapshots. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].snapshot_window : null
}

# =============================================================================
# Membership and Status
# =============================================================================

output "cluster_address_ipv4" {
  description = "The IPv4 address of the primary cache node (if available). Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].primary_endpoint_address : null
}

output "cache_node_type_info" {
  description = "Information about the cache node type including resource specifics. Only for provisioned mode."
  value = var.deployment_mode == "provisioned" ? (
    {
      node_type              = aws_elasticache_replication_group.provisioned[0].node_type
      parameter_group_family = var.parameter_group_family
    }
  ) : null
}

# =============================================================================
# Logging Configuration
# =============================================================================

output "log_delivery_enabled" {
  description = "Whether log delivery is configured for the cluster. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? (length(var.log_delivery_configuration) > 0) : null
}

output "log_delivery_configuration" {
  description = "Log delivery configuration for the cluster. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? var.log_delivery_configuration : null
}

output "slow_log_group_name" {
  description = "CloudWatch log group name for slow-log. Only available when create_log_groups is true."
  value       = var.cloudwatch_log_enabled && var.create_log_groups ? aws_cloudwatch_log_group.slow_log[0].name : null
}

output "engine_log_group_name" {
  description = "CloudWatch log group name for engine-log. Only available when create_log_groups is true."
  value       = var.cloudwatch_log_enabled && var.create_log_groups ? aws_cloudwatch_log_group.engine_log[0].name : null
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================

output "alarm_cpu_utilization_arn" {
  description = "ARN of the CPU utilization alarm. Only available when create_alarms is true."
  value       = var.create_alarms && var.deployment_mode == "provisioned" ? aws_cloudwatch_metric_alarm.cpu_utilization[0].arn : null
}

output "alarm_evictions_arn" {
  description = "ARN of the evictions alarm. Only available when create_alarms is true."
  value       = var.create_alarms && var.deployment_mode == "provisioned" ? aws_cloudwatch_metric_alarm.evictions[0].arn : null
}

output "alarm_connections_arn" {
  description = "ARN of the connections alarm. Only available when create_alarms is true."
  value       = var.create_alarms && var.deployment_mode == "provisioned" ? aws_cloudwatch_metric_alarm.current_connections[0].arn : null
}

output "alarm_memory_usage_arn" {
  description = "ARN of the memory usage alarm. Only available when create_alarms is true."
  value       = var.create_alarms && var.deployment_mode == "provisioned" ? aws_cloudwatch_metric_alarm.database_memory_usage_percentage[0].arn : null
}

output "alarm_engine_cpu_arn" {
  description = "ARN of the engine CPU utilization alarm. Only available when create_alarms is true."
  value       = var.create_alarms && var.deployment_mode == "provisioned" ? aws_cloudwatch_metric_alarm.engine_cpu_utilization[0].arn : null
}

# =============================================================================
# SNS Topic
# =============================================================================

output "sns_topic_arn" {
  description = "ARN of the SNS topic for ElastiCache notifications and alarms. Only available when create_sns_topic is true."
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].arn : null
}

output "sns_topic_name" {
  description = "Name of the SNS topic for ElastiCache notifications and alarms. Only available when create_sns_topic is true."
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].name : null
}

output "alert_email_subscriptions" {
  description = "Email addresses subscribed to alerts. Subscriptions require email confirmation from AWS."
  value       = var.create_sns_topic ? var.alert_email_addresses : []
}

# =============================================================================
# Maintenance and Monitoring
# =============================================================================

output "maintenance_window" {
  description = "The maintenance window for the cluster. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].maintenance_window : null
}

output "notification_topic_arn" {
  description = "The ARN of the SNS topic for cluster notifications, if configured. Only for provisioned mode."
  value       = var.deployment_mode == "provisioned" ? aws_elasticache_replication_group.provisioned[0].notification_topic_arn : null
}

# =============================================================================
# Authentication Secret
# =============================================================================

output "auth_secret_arn" {
  description = "The ARN of the Secrets Manager secret storing the auth token. Only available when auth_token_enabled is true."
  value       = var.auth_token_enabled ? aws_secretsmanager_secret.auth_token[0].arn : null
}

output "auth_secret_name" {
  description = "The name of the Secrets Manager secret storing the auth token. Only available when auth_token_enabled is true."
  value       = var.auth_token_enabled ? aws_secretsmanager_secret.auth_token[0].name : null
}

output "auth_secret_id" {
  description = "The ID of the Secrets Manager secret storing the auth token. Only available when auth_token_enabled is true."
  value       = var.auth_token_enabled ? aws_secretsmanager_secret.auth_token[0].id : null
}

# =============================================================================
# Route53 DNS Record
# =============================================================================

output "route53_record_name" {
  description = "The Route53 DNS record name created for the ElastiCache endpoint. Defaults to cluster_id if route53_record_name is not provided. Only available when create_route53_record is true."
  value       = var.create_route53_record ? aws_route53_record.valkey[0].name : null
}

output "route53_record_fqdn" {
  description = "The fully qualified domain name of the Route53 record with port. Use this in your application configuration for DNS resolution. Defaults to cluster_id if route53_record_name is not provided. Only available when create_route53_record is true."
  value       = var.create_route53_record ? "${aws_route53_record.valkey[0].name}:${var.port}" : null
}
