# Return the hosted-zone ID used by records and other AWS services.
output "zone_id" {
  description = "Route 53 hosted-zone ID."
  value       = aws_route53_zone.this.zone_id
}

# Expose the normalized zone name and privacy setting.
output "zone_name" {
  description = "DNS name of the hosted zone."
  value       = aws_route53_zone.this.name
}

output "private_zone" {
  description = "Whether this is a private hosted zone."
  value       = var.private_zone
}

# Public zones receive authoritative name servers; private zones generally return an empty list.
output "name_servers" {
  description = "Authoritative name servers assigned to a public hosted zone."
  value       = aws_route53_zone.this.name_servers
}

# Return configured VPC associations for private hosted zones.
output "vpc_associations" {
  description = "VPC IDs and regions associated with the hosted zone."
  value       = aws_route53_zone.this.vpc
}

# Make each managed record's FQDN available to callers.
output "record_fqdns" {
  description = "Fully qualified DNS names for managed records, keyed by the caller's record key."
  value       = { for key, record in aws_route53_record.this : key => record.fqdn }
}

# Expose full managed-record objects for consumers that need record IDs or configuration.
output "records" {
  description = "Managed Route 53 records keyed by caller key."
  value       = aws_route53_record.this
}

# Expose the query logging configuration and its CloudWatch destination.
output "query_logging_enabled" {
  description = "Whether Route 53 DNS query logging is enabled."
  value       = var.enable_query_logging
}

output "query_log_group_name" {
  description = "CloudWatch log group name, or null when query logging is disabled."
  value       = var.enable_query_logging ? aws_cloudwatch_log_group.route53_query_logs[0].name : null
}

output "query_log_group_arn" {
  description = "CloudWatch log group ARN, or null when query logging is disabled."
  value       = var.enable_query_logging ? aws_cloudwatch_log_group.route53_query_logs[0].arn : null
}

output "query_log_configuration_id" {
  description = "Route 53 query logging configuration ID, or null when query logging is disabled."
  value       = var.enable_query_logging ? aws_route53_query_log.this[0].id : null
}
