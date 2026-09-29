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

variable "database_name" {
  description = "Name of the initial PostgreSQL database to create."
  type        = string
  default     = null
}

variable "master_username" {
  description = "Master username for the PostgreSQL database."
  type        = string
}

variable "master_password" {
  description = "Master password for the PostgreSQL database."
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Port on which PostgreSQL accepts connections."
  type        = number
  default     = 5432
}

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

variable "multi_az" {
  description = "Whether to deploy the RDS instance as a Multi-AZ deployment."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups. Set to 0 to disable automated backups."
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred daily time range for automated backups, in UTC."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred weekly maintenance window, in UTC."
  type        = string
  default     = "sun:04:00-sun:05:00"
}

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

variable "parameter_group_name" {
  description = "Optional existing DB parameter group name."
  type        = string
  default     = null
}

variable "option_group_name" {
  description = "Optional existing DB option group name."
  type        = string
  default     = null
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
    from_port                    = number
    to_port                      = number
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
    from_port                    = number
    to_port                      = number
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the RDS instance, subnet group, and security group."
  type        = map(string)
  default     = {}
}