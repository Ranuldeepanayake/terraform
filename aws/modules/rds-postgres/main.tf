# -----------------------------------------------------------------------------
# RDS subnet group
#
# The VPC and subnets are NOT created by this module.
# The caller supplies existing subnet IDs.
# -----------------------------------------------------------------------------

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
}

# -----------------------------------------------------------------------------
# PostgreSQL RDS instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "this" {
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
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.port

  # Networking.
  db_subnet_group_name = aws_db_subnet_group.this.name

  # Use either the newly created security group or existing security groups.
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids

  publicly_accessible = var.publicly_accessible

  # IAM configuration.
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # High availability.
  multi_az = var.multi_az

  # Backup configuration.
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window

  # Maintenance configuration.
  maintenance_window          = var.maintenance_window
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade

  # Existing parameter/option groups can optionally be supplied.
  parameter_group_name = var.parameter_group_name
  option_group_name    = var.option_group_name

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
    aws_db_subnet_group.this
  ]
}