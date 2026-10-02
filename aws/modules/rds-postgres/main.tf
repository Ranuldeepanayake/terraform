# -----------------------------------------------------------------------------
# RDS subnet group
#
# The VPC and subnets are NOT created by this module.
# The caller supplies existing subnet IDs.
# -----------------------------------------------------------------------------

# Creates the DB subnet group from caller-provided subnets.
resource "aws_db_subnet_group" "this" {
  name_prefix = var.identifier
  description = "Subnet group for RDS PostgreSQL instance ${var.identifier}"

  # Existing subnet IDs supplied by the caller.
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      ResourceType = "subnet-group"
    }
  )

  lifecycle {
    precondition {
      condition = var.deployment_mode != "multi_az_cluster" || (
        var.cluster_instance_class != null && can(regex("^db\\.(c6gd|m5d|m6gd|m6id|m6idn|m8gd|r5d|r6gd|r6id|r6idn|r8gd|x2iedn)\\.", var.cluster_instance_class))
      )
      error_message = "multi_az_cluster requires a supported cluster_instance_class (for example db.m6gd.xlarge)."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || length(var.subnet_ids) >= 3
      error_message = "multi_az_cluster requires a DB subnet group spanning at least three Availability Zones; provide at least three subnet IDs in distinct AZs."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || var.max_allocated_storage == 0 || var.max_allocated_storage == var.allocated_storage
      error_message = "max_allocated_storage is not supported in multi_az_cluster mode; set it to 0 or allocated_storage."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || var.option_group_name == null
      error_message = "option_group_name is not supported in multi_az_cluster mode."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || (var.backups_enabled && var.backup_retention_period >= 1)
      error_message = "multi_az_cluster requires automated backups with backup_retention_period of at least 1 day."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || !var.multi_az
      error_message = "Set multi_az=false with deployment_mode=multi_az_cluster; the cluster architecture is inherently Multi-AZ."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || !var.publicly_accessible
      error_message = "multi_az_cluster mode does not support publicly_accessible=true; access the cluster through its VPC security group."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || length(var.read_replicas) == 0
      error_message = "Do not configure read_replicas in multi_az_cluster mode; RDS creates two readers as part of the cluster."
    }
  }
}

# -----------------------------------------------------------------------------
# PostgreSQL RDS instance
# -----------------------------------------------------------------------------

# Creates the PostgreSQL DB instance with the configured options.
resource "aws_db_instance" "this" {
  count = var.deployment_mode == "db_instance" ? 1 : 0

  identifier = var.identifier

  # PostgreSQL engine configuration.
  engine         = "postgres"
  engine_version = var.engine_version

  # Instance sizing.
  instance_class = var.instance_class

  # Storage configuration.
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  # Database configuration.
  db_name                     = var.database_name
  username                    = var.master_username
  manage_master_user_password = var.manage_master_user_password ? true : null
  password                    = var.manage_master_user_password ? null : var.master_password
  port                        = var.port

  # Networking.
  db_subnet_group_name = aws_db_subnet_group.this.name

  # Use either the newly created security group or existing security groups.
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids

  # Create a public IP address for the RDS instance.
  publicly_accessible = var.publicly_accessible

  # IAM configuration.
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  monitoring_interval                 = var.monitoring_interval
  monitoring_role_arn                 = local.monitoring_role_arn

  # Export selected PostgreSQL logs to CloudWatch Logs.
  enabled_cloudwatch_logs_exports = var.cloudwatch_log_exports

  # High availability.
  multi_az = var.multi_az

  # Backup configuration.
  backup_retention_period = var.backups_enabled ? var.backup_retention_period : 0
  backup_window           = var.backup_window

  # Maintenance configuration.
  maintenance_window          = var.maintenance_window
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade

  # Existing parameter/option groups can optionally be supplied.
  parameter_group_name = local.effective_parameter_group_name
  option_group_name    = var.option_group_name

  # Snapshot configuration.
  copy_tags_to_snapshot = var.copy_tags_to_snapshot
  snapshot_identifier   = var.snapshot_identifier

  # Lifecycle configuration.
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier
  apply_immediately         = var.apply_immediately

  tags = merge(
    var.tags,
    {
      ResourceType = "rds-instance"
    }
  )

  depends_on = [
    aws_db_subnet_group.this,
    aws_cloudwatch_log_group.rds,
    aws_iam_role_policy_attachment.rds_enhanced_monitoring
  ]

  lifecycle {
    precondition {
      condition     = var.manage_master_user_password ? (var.master_password == null) : (var.master_password != null)
      error_message = "Set manage_master_user_password to true and leave master_password null, or set it to false and provide master_password."
    }

    precondition {
      condition     = var.monitoring_interval == 0 || var.create_monitoring_role || var.monitoring_role_arn != null
      error_message = "Enhanced monitoring requires create_monitoring_role=true or a monitoring_role_arn when monitoring_interval is non-zero."
    }

    precondition {
      condition     = length(var.postgres_parameters) == 0 || var.parameter_group_family != null
      error_message = "parameter_group_family is required when postgres_parameters are configured."
    }

    precondition {
      condition     = length(var.postgres_parameters) == 0 || var.parameter_group_name == null
      error_message = "Set either parameter_group_name or postgres_parameters, not both."
    }

    precondition {
      condition     = length(var.read_replicas) == 0 || var.backups_enabled
      error_message = "Automated backups must be enabled when creating read replicas."
    }

    precondition {
      condition     = !var.backups_enabled || var.backup_retention_period > 0
      error_message = "backup_retention_period must be greater than zero when backups_enabled is true."
    }

    precondition {
      condition = var.deployment_mode != "multi_az_cluster" || (
        var.cluster_instance_class != null && can(regex("^db\\.(c6gd|m5d|m6gd|m6id|m6idn|m8gd|r5d|r6gd|r6id|r6idn|r8gd|x2iedn)\\.", var.cluster_instance_class))
      )
      error_message = "multi_az_cluster requires a supported cluster_instance_class (for example db.m6gd.xlarge)."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || length(var.subnet_ids) >= 3
      error_message = "multi_az_cluster requires a DB subnet group spanning at least three Availability Zones; provide at least three subnet IDs."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || (var.backups_enabled && var.backup_retention_period >= 1)
      error_message = "multi_az_cluster requires automated backups with backup_retention_period of at least 1 day."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || !var.multi_az
      error_message = "Set multi_az=false with deployment_mode=multi_az_cluster; the cluster architecture is inherently Multi-AZ."
    }

    precondition {
      condition     = var.deployment_mode != "multi_az_cluster" || length(var.read_replicas) == 0
      error_message = "Do not configure read_replicas in multi_az_cluster mode; RDS creates two readers as part of the cluster."
    }
  }
}

# Creates the Multi-AZ cluster architecture with one writer and two readers.
resource "aws_rds_cluster" "multi_az" {
  count = var.deployment_mode == "multi_az_cluster" ? 1 : 0

  cluster_identifier          = var.identifier
  engine                      = "postgres"
  engine_version              = var.engine_version
  db_cluster_instance_class   = var.cluster_instance_class
  allocated_storage           = var.allocated_storage
  storage_type                = var.storage_type
  database_name               = var.database_name
  master_username             = var.master_username
  manage_master_user_password = var.manage_master_user_password ? true : null
  master_password             = var.manage_master_user_password ? null : var.master_password
  port                        = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  monitoring_interval                 = var.monitoring_interval
  monitoring_role_arn                 = local.monitoring_role_arn
  enabled_cloudwatch_logs_exports     = var.cloudwatch_log_exports

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  db_cluster_parameter_group_name = local.effective_parameter_group_name
  copy_tags_to_snapshot           = var.copy_tags_to_snapshot
  snapshot_identifier             = var.snapshot_identifier
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.final_snapshot_identifier
  apply_immediately               = var.apply_immediately
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade

  tags = merge(
    var.tags,
    {
      ResourceType = "rds-multi-az-cluster"
    }
  )

  depends_on = [
    aws_db_subnet_group.this,
    aws_cloudwatch_log_group.rds,
    aws_iam_role_policy_attachment.rds_enhanced_monitoring
  ]

  lifecycle {
    precondition {
      condition     = var.manage_master_user_password ? (var.master_password == null) : (var.master_password != null)
      error_message = "Set manage_master_user_password to true and leave master_password null, or set it to false and provide master_password."
    }
  }
}

# Migrates the original uncounted instance address into the default instance mode.
moved {
  from = aws_db_instance.this
  to   = aws_db_instance.this[0]
}