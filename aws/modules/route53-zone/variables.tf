# The DNS name managed by the hosted zone.
variable "zone_name" {
  description = "DNS domain name for the hosted zone, for example example.com."
  type        = string

  validation {
    condition     = trimspace(var.zone_name) != "" && !endswith(var.zone_name, ".")
    error_message = "zone_name must be a non-empty DNS name without a trailing dot."
  }
}

# Mark the zone private and associate it with the requested VPCs.
variable "private_zone" {
  description = "Create a VPC-associated private hosted zone instead of a public zone."
  type        = bool
  default     = false
}

# AWS requires at least one VPC association when creating a private zone.
variable "vpc_associations" {
  description = "VPCs associated with a private hosted zone; region defaults to the caller's AWS provider region."
  type = list(object({
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = []

  validation {
    condition = (
      length(distinct([for association in var.vpc_associations : association.vpc_id])) == length(var.vpc_associations) &&
      alltrue([for association in var.vpc_associations : trimspace(association.vpc_id) != ""]) &&
      (!var.private_zone || length(var.vpc_associations) > 0)
    )
    error_message = "vpc_associations must contain unique, non-empty VPC IDs; a private zone requires at least one VPC."
  }
}

# The comment is visible in the Route 53 hosted-zone console.
variable "comment" {
  description = "Optional hosted-zone comment."
  type        = string
  default     = null
  nullable    = true
}

# Prevent accidental destruction of zones containing DNS records by default.
variable "force_destroy" {
  description = "Allow Terraform to delete this hosted zone even when it contains records other than NS and SOA."
  type        = bool
  default     = false
}

# Optional reusable Route 53 delegation set for a public zone.
variable "delegation_set_id" {
  description = "Optional Route 53 reusable delegation set ID; valid for public hosted zones."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.delegation_set_id == null || !var.private_zone
    error_message = "delegation_set_id can only be used with a public hosted zone."
  }
}

# Tags applied to the hosted zone.
variable "tags" {
  description = "Tags applied to the hosted zone."
  type        = map(string)
  default     = {}
}

# Enable public DNS query logging to a CloudWatch Logs group in us-east-1.
variable "enable_query_logging" {
  description = "Whether to send public hosted-zone DNS query logs to CloudWatch Logs."
  type        = bool
  default     = false
}

# Optional CloudWatch log group name; defaults to /aws/route53/<zone>/query-logs.
variable "query_log_group_name" {
  description = "Optional CloudWatch log group name for Route 53 query logs."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.query_log_group_name == null || trimspace(var.query_log_group_name) != ""
    error_message = "query_log_group_name must be null or a non-empty name."
  }
}

# Bound query-log storage costs by expiring old events.
variable "query_log_retention_in_days" {
  description = "Retention period for the Route 53 query log group."
  type        = number
  default     = 7

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096,
      1827, 2192, 2557, 2922, 3288, 3653
    ], var.query_log_retention_in_days)
    error_message = "query_log_retention_in_days must be one of the retention periods supported by CloudWatch Logs."
  }
}

# DNS record definitions keyed by stable caller-chosen Terraform instance keys.
variable "records" {
  description = "Map of simple, alias, or routed Route 53 records. Supports standard, weighted, latency, failover, geolocation, geoproximity, CIDR, and multivalue routing."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.records))
    error_message = "records must be a map or object keyed by stable record identifiers."
  }
}
