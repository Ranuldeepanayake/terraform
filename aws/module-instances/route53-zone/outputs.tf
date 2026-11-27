# Expose the hosted-zone identity and whether it is public or private.
output "zone_id" {
  description = "Route 53 hosted-zone ID."
  value       = module.ranul_click.zone_id
}

# Expose the normalized zone name.
output "zone_name" {
  description = "Hosted-zone DNS name."
  value       = module.ranul_click.zone_name
}

# Expose whether the zone is private.
output "private_zone" {
  description = "Whether the hosted zone is private."
  value       = module.ranul_click.private_zone
}

# Return authoritative name servers for public DNS delegation.
output "name_servers" {
  description = "Authoritative name servers assigned to the hosted zone."
  value       = module.ranul_click.name_servers
}

# Return the FQDN for each record declared by the JSON map.
output "record_fqdns" {
  description = "Managed record FQDNs keyed by the JSON record-map keys."
  value       = module.ranul_click.record_fqdns
}

output "query_logging_enabled" {
  description = "Whether Route 53 DNS query logging is enabled."
  value       = module.ranul_click.query_logging_enabled
}

output "query_log_group_name" {
  description = "CloudWatch log group receiving public DNS query logs."
  value       = module.ranul_click.query_log_group_name
}

output "query_log_group_arn" {
  description = "CloudWatch log group ARN receiving public DNS query logs."
  value       = module.ranul_click.query_log_group_arn
}

output "query_log_configuration_id" {
  description = "Route 53 query logging configuration ID."
  value       = module.ranul_click.query_log_configuration_id
}
