# =============================================================================
# ElastiCache Valkey Cluster Configuration
# =============================================================================

# Deployment mode selection
variable "deployment_mode" {
  description = "Deployment mode: 'provisioned' for managed nodes or 'serverless' for auto-scaling capacity."
  type        = string
  default     = "provisioned"

  validation {
    condition     = var.deployment_mode == "provisioned" || var.deployment_mode == "serverless"
    error_message = "deployment_mode must be 'provisioned' or 'serverless'."
  }
}

# Basic cluster identity and configuration
variable "cluster_id" {
  description = "Unique identifier for the ElastiCache Valkey cluster."
  type        = string
}

variable "engine_version" {
  description = "Valkey engine version to use (e.g., 8.0, 9.0). Check AWS docs for supported versions."
  type        = string
  default     = "8.0"
}

variable "node_type" {
  description = "Node type for the cluster (e.g., cache.t4g.micro, cache.m7g.large). Only used for provisioned mode. Determines CPU, memory, and network performance."
  type        = string
  default     = "cache.t4g.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes in the cluster. Only used for provisioned mode. For non-clustered mode, this should be 1."
  type        = number
  default     = 1

  validation {
    condition     = var.num_cache_nodes >= 1 && var.num_cache_nodes <= 500
    error_message = "num_cache_nodes must be between 1 and 500."
  }
}

# Serverless-specific configuration
variable "serverless_cache_size" {
  description = "Serverless cache size in GB (256 GB increments). Only used for serverless mode. Options: 1, 2, 4, 8, 16, 32, 64, 128, 256."
  type        = number
  default     = 1

  validation {
    condition = contains([1, 2, 4, 8, 16, 32, 64, 128, 256], var.serverless_cache_size)
    error_message = "serverless_cache_size must be one of: 1, 2, 4, 8, 16, 32, 64, 128, 256."
  }
}

# =============================================================================
# Cluster Mode and Replication
# =============================================================================

variable "automatic_failover_enabled" {
  description = "Enable automatic failover for Multi-AZ deployments. Only used for provisioned mode. Requires at least 2 cache nodes and replicas_per_shard > 0."
  type        = bool
  default     = false
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ replication with automatic failover across Availability Zones. Only used for provisioned mode."
  type        = bool
  default     = false
}

# =============================================================================
# Performance and Optimization
# =============================================================================

variable "parameter_group_family" {
  description = "ElastiCache Valkey parameter group family (e.g., 'valkey8', 'valkey9'). Must match the major version of engine_version. Only used for provisioned mode."
  type        = string
  default     = null
  nullable    = true
}

variable "parameter_group_name" {
  description = "Name of the ElastiCache parameter group to associate. If null, a new custom parameter group will be created. Only used for provisioned mode."
  type        = string
  default     = null
}

variable "parameters" {
  description = "Map of parameter names to values for custom parameter group configuration. Only used when parameter_group_name is null and deployment_mode is provisioned."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.parameters :
      can(regex("^[a-z0-9-]+$", key)) && length(key) > 0 && length(value) > 0
    ])
    error_message = "All parameters must have non-empty valid keys and values."
  }
}

# =============================================================================
# Networking
# =============================================================================

variable "subnet_group_name" {
  description = "Name of the ElastiCache subnet group. If null, the module will create one with a name_prefix."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of existing subnet IDs for the ElastiCache cluster. Required for cluster deployment."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
}

variable "port" {
  description = "Port on which Valkey accepts connections. Default is 6379."
  type        = number
  default     = 6379

  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "port must be between 1024 and 65535."
  }
}

# =============================================================================
# Security
# =============================================================================

variable "create_security_group" {
  description = "Whether to create a new security group for the ElastiCache cluster. If false, existing security group IDs must be provided."
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of existing security group IDs to associate with the cluster. Only used when create_security_group is false."
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created. Required when create_security_group is true."
  type        = string
  default     = null
}

variable "security_group_ingress_rules" {
  description = "Ingress rules for the security group. Define rules for each allowed source."
  type = map(object({
    description                  = optional(string)
    from_port                    = number
    to_port                      = number
    protocol                     = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}
}

variable "security_group_egress_rules" {
  description = "Egress rules for the security group. If empty, a default rule allowing all outbound traffic is created."
  type = map(object({
    description                  = optional(string)
    from_port                    = number
    to_port                      = number
    protocol                     = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}
}

variable "auth_token_enabled" {
  description = "Enable Redis authentication using a token. When enabled, auth_token must be provided and a Secrets Manager secret will be created."
  type        = bool
  default     = false
}

variable "auth_token" {
  description = "Authentication token for Valkey. Required when auth_token_enabled is true. Must be 16-128 characters."
  type        = string
  sensitive   = true
  default     = null
}

variable "auth_secret_name" {
  description = "Name for the Secrets Manager secret storing the auth token. If null, a name is auto-generated. Only used when auth_token_enabled is true."
  type        = string
  default     = null
}

# =============================================================================
# Encryption and Data Protection
# =============================================================================

variable "at_rest_encryption_enabled" {
  description = "Enable encryption of data at rest using AWS KMS. Supported only for certain node types."
  type        = bool
  default     = false
}

variable "at_rest_encryption_kms_key_id" {
  description = "ARN of the KMS key used for at-rest encryption. If null, the default AWS managed key is used."
  type        = string
  default     = null
}

variable "transit_encryption_enabled" {
  description = "Enable encryption of data in transit using TLS. Supported only for certain node types."
  type        = bool
  default     = false
}

variable "transit_encryption_mode" {
  description = "TLS encryption mode: 'preferred' or 'required'. Only used when transit_encryption_enabled is true."
  type        = string
  default     = "preferred"

  validation {
    condition     = var.transit_encryption_mode == "preferred" || var.transit_encryption_mode == "required"
    error_message = "transit_encryption_mode must be 'preferred' or 'required'."
  }
}

# =============================================================================
# Logging and Monitoring
# =============================================================================

variable "cloudwatch_log_enabled" {
  description = "Enable CloudWatch Logs for slow-log and engine-log exports."
  type        = bool
  default     = false
}

variable "create_log_groups" {
  description = "Create CloudWatch log groups for slow-log and engine-log. Only used when cloudwatch_log_enabled is true."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days. Only used when create_log_groups is true."
  type        = number
  default     = 7

  validation {
    condition     = var.log_retention_days > 0
    error_message = "log_retention_days must be greater than 0."
  }
}

variable "slow_log_group_name" {
  description = "Custom CloudWatch log group name for slow-log. If null and create_log_groups is true, auto-generated as /aws/elasticache/valkey/{cluster_id}/slow-log."
  type        = string
  default     = null
}

variable "engine_log_group_name" {
  description = "Custom CloudWatch log group name for engine-log. If null and create_log_groups is true, auto-generated as /aws/elasticache/valkey/{cluster_id}/engine-log."
  type        = string
  default     = null
}

variable "log_delivery_configuration" {
  description = "Configuration for CloudWatch Logs delivery. Includes slow-log and engine-log settings."
  type = map(object({
    enabled                   = bool
    log_format                = string
    cloudwatch_log_group_name = optional(string)
  }))
  default = {}
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic cache snapshots. Set to 0 to disable snapshots. Only used for provisioned mode."
  type        = number
  default     = 0

  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "snapshot_retention_limit must be between 0 and 35."
  }
}

variable "snapshot_window" {
  description = "Daily time window for taking automatic snapshots (e.g., '03:00-05:00'). Only used when snapshot_retention_limit > 0 and deployment_mode is provisioned."
  type        = string
  default     = "03:00-05:00"
}

# =============================================================================
# Maintenance and Upgrades
# =============================================================================

variable "maintenance_window" {
  description = "Weekly maintenance window in UTC (e.g., 'sun:03:00-sun:04:00')."
  type        = string
  default     = "sun:03:00-sun:04:00"
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades."
  type        = bool
  default     = true
}

variable "create_sns_topic" {
  description = "Create SNS topic for ElastiCache notifications and alarm alerts. If false, notification_topic_arn must be provided."
  type        = bool
  default     = false
}

variable "alert_email_addresses" {
  description = "Email addresses to receive alerts. Only used when create_sns_topic is true. Subscriptions require email confirmation."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([
      for email in var.alert_email_addresses :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All alert_email_addresses must be valid email addresses."
  }
}

variable "notification_topic_arn" {
  description = "ARN of the SNS topic for ElastiCache notifications and alarm alerts. Required when create_sns_topic is false."
  type        = string
  default     = null
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================

variable "create_alarms" {
  description = "Create CloudWatch alarms for ElastiCache cluster health monitoring."
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold (%) for high CPU alarm. Only used when create_alarms is true."
  type        = number
  default     = 75

  validation {
    condition     = var.alarm_cpu_threshold > 0 && var.alarm_cpu_threshold <= 100
    error_message = "alarm_cpu_threshold must be between 1 and 100."
  }
}

variable "alarm_eviction_threshold" {
  description = "Number of evictions per minute for high eviction alarm. Only used when create_alarms is true."
  type        = number
  default     = 1000

  validation {
    condition     = var.alarm_eviction_threshold >= 0
    error_message = "alarm_eviction_threshold must be >= 0."
  }
}

variable "alarm_connection_threshold" {
  description = "Number of client connections for high connection alarm. Only used when create_alarms is true."
  type        = number
  default     = 1000

  validation {
    condition     = var.alarm_connection_threshold > 0
    error_message = "alarm_connection_threshold must be > 0."
  }
}

variable "alarm_memory_threshold" {
  description = "Database memory usage percentage for high memory alarm. Only used when create_alarms is true."
  type        = number
  default     = 80

  validation {
    condition     = var.alarm_memory_threshold > 0 && var.alarm_memory_threshold <= 100
    error_message = "alarm_memory_threshold must be between 1 and 100."
  }
}

variable "custom_alarms" {
  description = "Map of custom CloudWatch alarms to create. Alarms will send to notification_topic_arn."
  type = map(object({
    metric_name         = string
    namespace           = optional(string, "AWS/ElastiCache")
    statistic           = optional(string, "Average")
    period              = optional(number, 300)
    evaluation_periods  = optional(number, 2)
    comparison_operator = string
    threshold           = number
    alarm_description   = optional(string)
  }))
  default = {}
}

# =============================================================================
# Lifecycle and Tags
# =============================================================================

variable "apply_immediately" {
  description = "Apply changes immediately instead of during the maintenance window."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all ElastiCache resources created by this module."
  type        = map(string)
  default     = {}
}

# =============================================================================
# Route53 DNS (Optional)
# =============================================================================

variable "create_route53_record" {
  description = "Whether to create a Route53 CNAME record for the ElastiCache endpoint. The record points to the private AWS endpoint for easier DNS resolution within your VPC. Note: ElastiCache endpoints are always private; Route53 records are purely for DNS convenience."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 private hosted zone ID where the DNS record will be created. Must be associated with your VPC. Required if create_route53_record is true."
  type        = string
  default     = null
}

variable "route53_record_name" {
  description = "DNS name for the Route53 record (e.g., 'cache.internal.example.com'). If not provided, defaults to the cluster_id. The resulting FQDN will be qualified by the hosted zone (e.g., cluster_id.zone_domain). Only used when create_route53_record is true."
  type        = string
  default     = null
}

variable "route53_ttl" {
  description = "TTL in seconds for the Route53 record. Lower values (60s) provide faster DNS updates when the endpoint changes. Only used when create_route53_record is true."
  type        = number
  default     = 60
}
