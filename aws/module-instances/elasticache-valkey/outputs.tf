output "cluster_arn" {
  value = module.elasticache_valkey.cluster_arn
}

output "cluster_id" {
  value = module.elasticache_valkey.cluster_id
}

output "primary_endpoint" {
  value = module.elasticache_valkey.primary_endpoint
}

output "cluster_address" {
  value = module.elasticache_valkey.cluster_address
}

output "cluster_port" {
  value = module.elasticache_valkey.cluster_port
}

output "auth_secret_arn" {
  value = module.elasticache_valkey.auth_secret_arn
}

output "auth_secret_name" {
  value = module.elasticache_valkey.auth_secret_name
}

output "auth_secret_id" {
  value = module.elasticache_valkey.auth_secret_id
}

output "slow_log_group_name" {
  value = module.elasticache_valkey.slow_log_group_name
}

output "engine_log_group_name" {
  value = module.elasticache_valkey.engine_log_group_name
}

output "alarm_cpu_utilization_arn" {
  value = module.elasticache_valkey.alarm_cpu_utilization_arn
}

output "alarm_evictions_arn" {
  value = module.elasticache_valkey.alarm_evictions_arn
}

output "alarm_connections_arn" {
  value = module.elasticache_valkey.alarm_connections_arn
}

output "alarm_memory_usage_arn" {
  value = module.elasticache_valkey.alarm_memory_usage_arn
}

output "alarm_engine_cpu_arn" {
  value = module.elasticache_valkey.alarm_engine_cpu_arn
}

output "sns_topic_arn" {
  value = module.elasticache_valkey.sns_topic_arn
}

output "sns_topic_name" {
  value = module.elasticache_valkey.sns_topic_name
}

output "alert_email_subscriptions" {
  value = module.elasticache_valkey.alert_email_subscriptions
}
