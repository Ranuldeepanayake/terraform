# Locals for common variables.
locals {
  aws_region = "ap-southeast-1"

  project_name     = "internal"
  db_instance_name = "common-db"

  private_subnet_ids = [
    "subnet-05066d6b11149cfaf",
    "subnet-0130d3bdc2a8a711c"
  ]

  tags = {
    Environment      = "dev"
    ProjectName      = local.project_name
    ResourceCategory = "iam"
    ManagedBy        = "terraform"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "ranuldeepanayake"

    workspaces = {
      name = "aws-dev-vpc-1"
    }
  }
}

module "postgres" {
  # Uses the local RDS PostgreSQL module.
  source = "../../modules/rds-postgres"

  #############################################################################
  # Networking
  #############################################################################

  # VPC ID from the existing remote VPC state.
  vpc_id = data.terraform_remote_state.vpc.outputs.id
  # Existing subnet IDs used by the DB subnet group.
  subnet_ids = local.private_subnet_ids

  #############################################################################
  # Instance identity, engine, and storage
  #############################################################################

  # Unique RDS instance identifier.
  identifier = "${local.project_name}-${local.db_instance_name}"
  # PostgreSQL engine version.
  engine_version = "18.4"
  # Compute size for the DB instance.
  instance_class = "db.t4g.micro"
  # Initial storage allocation in GiB.
  allocated_storage = 20
  # Maximum autoscaled storage in GiB.
  max_allocated_storage = 25
  # RDS storage type.
  storage_type = "gp3"
  # Encrypt storage at rest.
  storage_encrypted = true
  # Use the AWS-managed RDS storage key.
  kms_key_id = null

  #############################################################################
  # Database and credentials
  #############################################################################

  # Initial PostgreSQL database name.
  database_name = "s3app"
  # Master database username.
  master_username = "postgres"
  # Let RDS manage the master password in Secrets Manager.
  manage_master_user_password = true
  # Leave null when RDS manages the password.
  master_password = null
  # PostgreSQL listener port.
  port = 5432

  #############################################################################
  # Connectivity and authentication
  #############################################################################

  # Assign a public IP address to the DB instance.
  publicly_accessible = true
  # Allow PostgreSQL IAM database authentication.
  iam_database_authentication_enabled = true

  #############################################################################
  # Enhanced monitoring and CloudWatch logs
  #############################################################################

  # Enhanced Monitoring interval in seconds; 0 disables it.
  monitoring_interval = 60
  # Create the standard IAM role for Enhanced Monitoring.
  create_monitoring_role = true
  # Existing monitoring role ARN; unused when creating the role.
  monitoring_role_arn = null
  # PostgreSQL log types exported to CloudWatch Logs.
  cloudwatch_log_exports = ["postgresql", "upgrade", "iam-db-auth-error"]
  # Retention period for exported CloudWatch log groups.
  cloudwatch_log_retention_in_days = 7

  #############################################################################
  # Availability, backups, and maintenance
  #############################################################################

  # Select a standalone DB instance; use multi_az_cluster for the three-node cluster architecture.
  deployment_mode = "db_instance"
  # Cluster node class; only used in multi_az_cluster mode.
  cluster_instance_class = null
  # Add one failover standby when using db_instance deployment mode.
  multi_az = false
  # Disable automated backups for this instance.
  backups_enabled = false
  # Retention period used if automated backups are enabled.
  backup_retention_period = 7
  # Preferred daily backup window in UTC.
  backup_window = "03:00-04:00"
  # Preferred weekly maintenance window in UTC.
  maintenance_window = "sun:04:00-sun:05:00"

  #############################################################################
  # Snapshots and lifecycle
  #############################################################################

  # Disable deletion protection for this instance.
  deletion_protection = false
  # Create a final snapshot when destroying the instance.
  skip_final_snapshot = false
  # Let the provider generate a final snapshot identifier.
  final_snapshot_identifier = null
  # Copy instance tags to snapshots.
  copy_tags_to_snapshot = true
  # Existing snapshot to restore from, or null for a new instance.
  snapshot_identifier = null
  # Apply modifications at the next maintenance window.
  apply_immediately = false
  # Automatically install minor PostgreSQL engine upgrades.
  auto_minor_version_upgrade = false
  # Disallow major engine upgrades by default.
  allow_major_version_upgrade = false

  #############################################################################
  # PostgreSQL parameters and option groups
  #############################################################################

  # Use an existing parameter group, or null to use the default/custom list.
  parameter_group_name = null
  # PostgreSQL family used if custom parameters are provided.
  parameter_group_family = "postgres18"
  # PostgreSQL parameter settings; memory values use PostgreSQL kB units.
  postgres_parameters = [
    {
      name         = "max_connections"
      value        = "100"
      apply_method = "pending-reboot"
    },
    {
      name         = "shared_buffers"
      value        = "262144"
      apply_method = "pending-reboot"
    },
    {
      name         = "work_mem"
      value        = "4096"
      apply_method = "immediate"
    },
    {
      name         = "maintenance_work_mem"
      value        = "65536"
      apply_method = "immediate"
    },
    {
      name         = "effective_cache_size"
      value        = "524288"
      apply_method = "immediate"
    },
    {
      name         = "log_connections"
      value        = "all"
      apply_method = "immediate"
    },
    {
      name         = "log_disconnections"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "log_lock_waits"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "log_min_duration_statement"
      value        = "1000"
      apply_method = "immediate"
    }
  ]
  # Existing option group, or null for the engine default.
  option_group_name = null
  #############################################################################
  # Replicas, CloudWatch alarms, and snapshot export
  #############################################################################

  # Same-region read replicas to create.
  read_replicas = []
  # CloudWatch metric alarms for the primary DB instance.
  cloudwatch_alarms = [
    {
      # Alarm identifier for high active database connections.
      alarm_name = "${local.project_name}-${local.db_instance_name}-connections-high"
      # Monitor active PostgreSQL connections.
      metric_name = "DatabaseConnections"
      # Trigger when connections exceed the configured threshold.
      comparison_operator = "GreaterThanThreshold"
      # Alert above 80 concurrent connections.
      threshold = 80
      # Require two consecutive evaluation periods.
      evaluation_periods = 2
      # Evaluate metrics over five-minute periods.
      period = 300
      # Average the metric over each period.
      statistic = "Average"
      # Read the metric from the RDS namespace.
      namespace = "AWS/RDS"
      # Explain the condition represented by this alarm.
      alarm_description = "Database connections are above 80."
      # No notification action is configured by default.
      alarm_actions = []
      # No recovery action is configured by default.
      ok_actions = []
      # Use the primary DB instance dimension from the module.
      dimensions = {}
      # Treat missing datapoints as missing.
      treat_missing_data = "missing"
      # Evaluate and update this alarm.
      actions_enabled = true
    },
    {
      # Alarm identifier for high CPU utilization.
      alarm_name = "${local.project_name}-${local.db_instance_name}-cpu-high"
      # Monitor DB instance CPU utilization.
      metric_name = "CPUUtilization"
      # Trigger when CPU exceeds the configured threshold.
      comparison_operator = "GreaterThanThreshold"
      # Alert above 80 percent CPU utilization.
      threshold = 80
      # Require two consecutive evaluation periods.
      evaluation_periods = 2
      # Evaluate metrics over five-minute periods.
      period = 300
      # Average the metric over each period.
      statistic = "Average"
      # Read the metric from the RDS namespace.
      namespace = "AWS/RDS"
      # Explain the condition represented by this alarm.
      alarm_description = "DB CPU utilization is above 80 percent."
      # No notification action is configured by default.
      alarm_actions = []
      # No recovery action is configured by default.
      ok_actions = []
      # Use the primary DB instance dimension from the module.
      dimensions = {}
      # Treat missing datapoints as missing.
      treat_missing_data = "missing"
      # Evaluate and update this alarm.
      actions_enabled = true
    },
    {
      # Alarm identifier for low freeable memory.
      alarm_name = "${local.project_name}-${local.db_instance_name}-memory-low"
      # Monitor memory available to the DB instance.
      metric_name = "FreeableMemory"
      # Trigger when available memory falls below the threshold.
      comparison_operator = "LessThanThreshold"
      # Alert below 256 MiB of available memory.
      threshold = 268435456
      # Require two consecutive evaluation periods.
      evaluation_periods = 2
      # Evaluate metrics over five-minute periods.
      period = 300
      # Average the metric over each period.
      statistic = "Average"
      # Read the metric from the RDS namespace.
      namespace = "AWS/RDS"
      # Explain the condition represented by this alarm.
      alarm_description = "DB freeable memory is below 256 MiB."
      # No notification action is configured by default.
      alarm_actions = []
      # No recovery action is configured by default.
      ok_actions = []
      # Use the primary DB instance dimension from the module.
      dimensions = {}
      # Treat missing datapoints as missing.
      treat_missing_data = "missing"
      # Evaluate and update this alarm.
      actions_enabled = true
    },
    {
      # Alarm identifier for low free storage.
      alarm_name = "${local.project_name}-${local.db_instance_name}-storage-low"
      # Monitor available storage in bytes.
      metric_name = "FreeStorageSpace"
      # Trigger when available storage falls below the threshold.
      comparison_operator = "LessThanThreshold"
      # Alert below 10 GiB of available storage.
      threshold = 10737418240
      # Require two consecutive evaluation periods.
      evaluation_periods = 2
      # Evaluate metrics over five-minute periods.
      period = 300
      # Average the metric over each period.
      statistic = "Average"
      # Read the metric from the RDS namespace.
      namespace = "AWS/RDS"
      # Explain the condition represented by this alarm.
      alarm_description = "DB free storage is below 10 GiB."
      # No notification action is configured by default.
      alarm_actions = []
      # No recovery action is configured by default.
      ok_actions = []
      # Use the primary DB instance dimension from the module.
      dimensions = {}
      # Treat missing datapoints as missing.
      treat_missing_data = "missing"
      # Evaluate and update this alarm.
      actions_enabled = true
    },
    {
      # Alarm identifier for high read latency.
      alarm_name = "${local.project_name}-${local.db_instance_name}-read-latency-high"
      # Monitor average read latency in seconds.
      metric_name = "ReadLatency"
      # Trigger when latency exceeds the configured threshold.
      comparison_operator = "GreaterThanThreshold"
      # Alert above 20 milliseconds of read latency.
      threshold = 0.02
      # Require two consecutive evaluation periods.
      evaluation_periods = 2
      # Evaluate metrics over five-minute periods.
      period = 300
      # Average the metric over each period.
      statistic = "Average"
      # Read the metric from the RDS namespace.
      namespace = "AWS/RDS"
      # Explain the condition represented by this alarm.
      alarm_description = "DB read latency is above 20 milliseconds."
      # No notification action is configured by default.
      alarm_actions = []
      # No recovery action is configured by default.
      ok_actions = []
      # Use the primary DB instance dimension from the module.
      dimensions = {}
      # Treat missing datapoints as missing.
      treat_missing_data = "missing"
      # Evaluate and update this alarm.
      actions_enabled = true
    },
    {
      # Alarm identifier for high write latency.
      alarm_name = "${local.project_name}-${local.db_instance_name}-write-latency-high"
      # Monitor average write latency in seconds.
      metric_name = "WriteLatency"
      # Trigger when latency exceeds the configured threshold.
      comparison_operator = "GreaterThanThreshold"
      # Alert above 20 milliseconds of write latency.
      threshold = 0.02
      # Require two consecutive evaluation periods.
      evaluation_periods = 2
      # Evaluate metrics over five-minute periods.
      period = 300
      # Average the metric over each period.
      statistic = "Average"
      # Read the metric from the RDS namespace.
      namespace = "AWS/RDS"
      # Explain the condition represented by this alarm.
      alarm_description = "DB write latency is above 20 milliseconds."
      # No notification action is configured by default.
      alarm_actions = []
      # No recovery action is configured by default.
      ok_actions = []
      # Use the primary DB instance dimension from the module.
      dimensions = {}
      # Treat missing datapoints as missing.
      treat_missing_data = "missing"
      # Evaluate and update this alarm.
      actions_enabled = true
    }
  ]
  # Snapshot-to-S3 export settings; null disables export task creation.
  snapshot_export_configuration = null

  #############################################################################
  # Security groups
  #############################################################################

  # Create and associate a security group for the DB instance.
  create_security_group = true
  # Security group name prefix.
  security_group_name = "${local.project_name}-${local.db_instance_name}"
  # Security group description.
  security_group_description = "Security group for student PostgreSQL RDS"
  # Existing security group IDs; unused when creating a group.
  security_group_ids = []
  # Ingress rules for the created security group.
  security_group_ingress_rules = [
    {
      description = "PostgreSQL from IPv4 network"
      from_port   = 5432
      to_port     = 5432
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    },
    {
      description = "PostgreSQL from IPv6 network"
      from_port   = 5432
      to_port     = 5432
      ip_protocol = "tcp"
      cidr_ipv6   = "2001:db8:1234::/48"
    }
  ]
  # Egress rules for the created security group.
  security_group_egress_rules = [
    {
      description = "Allow all IPv4 outbound traffic"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    },
    {
      description = "Allow all IPv6 outbound traffic"
      ip_protocol = "-1"
      cidr_ipv6   = "::/0"
    }
  ]
  #############################################################################
  # Tags
  #############################################################################

  # Tags applied to the DB instance, subnet group, and created security group.
  tags = local.tags
}