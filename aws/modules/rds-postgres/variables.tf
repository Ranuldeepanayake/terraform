###############################################################################
# Instance identity, engine, and sizing
###############################################################################

variable "identifier" {
  description = "Unique identifier for the RDS PostgreSQL instance."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version to use for the RDS instance."
  type        = string
  default     = "18.4"
}

variable "instance_class" {
  description = "RDS DB instance class, for example db.t4g.micro."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial amount of storage allocated to the RDS instance in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage size in GiB that RDS can automatically scale to. Set to 0 to disable storage autoscaling."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type for the RDS instance, such as gp3, gp2, or io1."
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Whether storage encryption should be enabled."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional ARN or ID of the KMS key used to encrypt the RDS storage. If null, the AWS managed RDS KMS key is used."
  type        = string
  default     = null
}

###############################################################################
# Database and credentials
###############################################################################

variable "database_name" {
  description = "Name of the initial PostgreSQL database to create."
  type        = string
  default     = null
}

variable "master_username" {
  description = "Master username for the PostgreSQL database."
  type        = string
}

variable "manage_master_user_password" {
  description = "Whether RDS should generate and manage the master user password in AWS Secrets Manager. When true, master_password must be null."
  type        = bool
  default     = false
}

variable "master_password" {
  description = "User-supplied master password for the PostgreSQL database. Required when manage_master_user_password is false."
  type        = string
  sensitive   = true
  default     = null
}

variable "port" {
  description = "Port on which PostgreSQL accepts connections."
  type        = number
  default     = 5432
}

###############################################################################
# Networking and authentication
###############################################################################

variable "vpc_id" {
  description = "ID of the existing VPC in which the RDS instance will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of existing subnet IDs to use for the RDS subnet group. These should normally span multiple Availability Zones."
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the RDS instance should have a publicly accessible endpoint."
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication for the RDS instance."
  type        = bool
  default     = false
}

###############################################################################
# Enhanced monitoring and log exports
###############################################################################

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds. Set to 0 to disable; valid enabled values are 1, 5, 10, 15, 30, or 60."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be 0, 1, 5, 10, 15, 30, or 60 seconds."
  }
}

variable "create_monitoring_role" {
  description = "Create and attach the standard IAM role required for enhanced monitoring when monitoring_interval is enabled."
  type        = bool
  default     = true
}

variable "monitoring_role_arn" {
  description = "Existing IAM role ARN for enhanced monitoring when create_monitoring_role is false."
  type        = string
  default     = null
}

variable "cloudwatch_log_exports" {
  description = "PostgreSQL log types to publish to CloudWatch Logs. Supported values are postgresql, upgrade, and iam-db-auth-error."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for log_type in var.cloudwatch_log_exports : contains(["postgresql", "upgrade", "iam-db-auth-error"], log_type)])
    error_message = "cloudwatch_log_exports may contain postgresql, upgrade, and iam-db-auth-error."
  }
}

variable "cloudwatch_log_retention_in_days" {
  description = "Retention period in days for the CloudWatch log groups created for exported RDS logs."
  type        = number
  default     = 30
}

###############################################################################
# Availability and automated backups
###############################################################################

variable "deployment_mode" {
  description = "RDS architecture: db_instance provisions one DB instance, optionally with a Multi-AZ standby; multi_az_cluster provisions a writer and two readers across three AZs."
  type        = string
  default     = "db_instance"

  validation {
    condition     = contains(["db_instance", "multi_az_cluster"], var.deployment_mode)
    error_message = "deployment_mode must be db_instance or multi_az_cluster."
  }
}

variable "cluster_instance_class" {
  description = "Supported DB instance class for all nodes of a Multi-AZ DB cluster. Required in multi_az_cluster mode; for example db.m6gd.xlarge."
  type        = string
  default     = null
}

variable "multi_az" {
  description = "For deployment_mode=db_instance, whether to use a Multi-AZ DB instance with one standby. Not applicable to multi_az_cluster mode."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups. Set to 0 to disable automated backups."
  type        = number
  default     = 7
}

variable "backups_enabled" {
  description = "Whether automated backups are enabled. When false, backup_retention_period is set to 0."
  type        = bool
  default     = true
}

variable "backup_window" {
  description = "Preferred daily time range for automated backups, in UTC."
  type        = string
  default     = "03:00-04:00"
}

###############################################################################
# Maintenance and upgrades
###############################################################################

variable "maintenance_window" {
  description = "Preferred weekly maintenance window, in UTC."
  type        = string
  default     = "sun:04:00-sun:05:00"
}

###############################################################################
# Snapshots and deletion behavior
###############################################################################

variable "deletion_protection" {
  description = "Whether deletion protection should be enabled on the RDS instance."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when the RDS instance is destroyed."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Identifier for the final snapshot created when the RDS instance is destroyed."
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy DB instance tags to automated and manual snapshots."
  type        = bool
  default     = true
}

variable "snapshot_identifier" {
  description = "Optional DB snapshot identifier or ARN from which to restore the instance."
  type        = string
  default     = null
}

###############################################################################
# Apply and upgrade behavior
###############################################################################

variable "apply_immediately" {
  description = "Whether modifications to the RDS instance should be applied immediately."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Whether the RDS instance should automatically receive minor engine version upgrades."
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Whether major PostgreSQL engine version upgrades are allowed."
  type        = bool
  default     = false
}

###############################################################################
# Database parameter and option groups
###############################################################################

variable "parameter_group_name" {
  description = "Optional existing DB parameter group name. Cannot be combined with postgres_parameters."
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "Parameter group family for the module-created PostgreSQL parameter group, such as postgres18. Required when postgres_parameters is non-empty."
  type        = string
  default     = null
}

variable "postgres_parameters" {
  description = "PostgreSQL DB parameter group settings. When non-empty, the module creates and attaches a parameter group."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "option_group_name" {
  description = "Optional existing DB option group name."
  type        = string
  default     = null
}

###############################################################################
# Replication, alarms, and snapshot exports
###############################################################################

variable "read_replicas" {
  description = "Optional same-region PostgreSQL read replicas to create from the primary instance."
  type = list(object({
    identifier          = string
    instance_class      = string
    availability_zone   = optional(string)
    publicly_accessible = optional(bool, false)
  }))
  default = []
}

variable "cloudwatch_alarms" {
  description = "CloudWatch metric alarms for the primary DB instance. Alarm names must be unique."
  type = list(object({
    alarm_name          = string
    metric_name         = string
    comparison_operator = string
    threshold           = number
    evaluation_periods  = number
    period              = number
    statistic           = optional(string, "Average")
    namespace           = optional(string, "AWS/RDS")
    alarm_description   = optional(string)
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
    dimensions          = optional(map(string), {})
    treat_missing_data  = optional(string, "missing")
    actions_enabled     = optional(bool, true)
  }))
  default = []
}

variable "snapshot_export_configuration" {
  description = "Optional configuration to export an existing RDS DB snapshot to S3. The IAM role and bucket/KMS permissions must already exist."
  type = object({
    export_task_identifier = string
    source_arn             = string
    s3_bucket_name         = string
    iam_role_arn           = string
    kms_key_id             = string
    s3_prefix              = optional(string)
    export_only            = optional(list(string), [])
  })
  default = null
}

# --------------------------------------------------------------------------
# Security group configuration
# --------------------------------------------------------------------------

variable "create_security_group" {
  description = "Whether the module should create a new security group for the RDS instance."
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name of the security group to create when create_security_group is true."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group created by this module."
  type        = string
  default     = "Security group for PostgreSQL RDS instance"
}

variable "security_group_ids" {
  description = "Existing security group IDs to associate with the RDS instance when create_security_group is false."
  type        = list(string)
  default     = []
}

variable "security_group_ingress_rules" {
  description = "Ingress rules for the security group created by this module. Each object represents one security group rule."
  type = list(object({
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = []
}

variable "security_group_egress_rules" {
  description = "Egress rules for the security group created by this module. Each object represents one security group rule."
  type = list(object({
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = []
}

###############################################################################
# Security group configuration
###############################################################################

variable "tags" {
  description = "Tags to apply to the RDS instance, subnet group, and security group."
  type        = map(string)
  default     = {}
}