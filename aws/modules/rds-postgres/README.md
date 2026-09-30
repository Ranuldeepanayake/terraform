## RDS PostgreSQL Module

Creates Amazon RDS for PostgreSQL using either a DB instance or a Multi-AZ DB cluster, plus a DB subnet group and optionally a security group. The VPC and subnets must already exist; pass their IDs to the module.

## Public Access Networking

When `publicly_accessible = true` for `deployment_mode = "db_instance"`, **every subnet in the DB subnet group must be public**: each subnet's route table must have a route to an Internet Gateway. The VPC must also have DNS hostnames and DNS resolution enabled, and the attached security group must allow PostgreSQL traffic from the intended client addresses. A public endpoint alone does not make the instance reachable if these network paths are missing.

If using private subnets (as in the examples below), set `publicly_accessible = false` and connect from within the VPC or through an approved network path. Avoid opening database ingress to `0.0.0.0/0`; limit it to trusted source CIDRs.

## Availability Modes

`deployment_mode` selects the architecture:

- `db_instance` (default) creates one RDS DB instance. With `multi_az = true`, RDS maintains a second, synchronous standby in another Availability Zone and automatically promotes it if the primary fails. This standby is **failover-only**: it has no separate endpoint and cannot serve read traffic. Applications keep connecting to the DB instance endpoint.
- `multi_az_cluster` creates one writer and two RDS-managed reader instances across three Availability Zones. The readers are failover targets **and** can serve read traffic through the cluster reader endpoint.

In short: both architectures keep database copies in other Availability Zones, but only a Multi-AZ DB cluster provides readable standby instances. A traditional Multi-AZ DB instance has a failover-only standby. A **read replica** configured through `read_replicas` is also a separate DB instance with its own endpoint; automated backups must be enabled for the source instance.

Multi-AZ DB cluster mode requires a supported `cluster_instance_class` (for example `db.m6gd.xlarge`), subnets in at least three distinct Availability Zones, and automated backups with a retention period of at least one day. The `db.t4g.micro` class is not supported for this mode. Cluster mode does not support public accessibility, `max_allocated_storage` autoscaling, or `option_group_name`; cluster configuration uses a cluster parameter group instead. Access it through the VPC and associated security groups.

Changing an existing deployment from `db_instance` to `multi_az_cluster` is not an in-place conversion and does not migrate database contents. Plan a snapshot/restore or other data migration before switching modes.

## Deployment Examples

Each example assumes the caller has `var.vpc_id` and `var.private_subnet_ids`. RDS-managed credentials keep the password out of Terraform configuration.

### Single DB Instance

One DB instance, no standby and no read replica:

```hcl
module "postgres_single" {
	source = "../../modules/rds-postgres"

	identifier                  = "app-postgres"
	deployment_mode             = "db_instance"
	multi_az                    = false
	instance_class              = "db.t4g.micro"
	master_username             = "postgres"
	manage_master_user_password = true
	vpc_id                      = var.vpc_id
	subnet_ids                  = var.private_subnet_ids
	read_replicas               = []
}
```

### DB Instance With Read Replica

The primary remains a single-AZ DB instance. The replica is a separate instance with its own endpoint, and can serve read-only application traffic:

```hcl
module "postgres_with_replica" {
	source = "../../modules/rds-postgres"

	identifier                  = "app-postgres"
	deployment_mode             = "db_instance"
	multi_az                    = false
	instance_class              = "db.t4g.micro"
	master_username             = "postgres"
	manage_master_user_password = true
	vpc_id                      = var.vpc_id
	subnet_ids                  = var.private_subnet_ids

	backups_enabled         = true
	backup_retention_period = 7
	read_replicas = [
		{
			identifier     = "app-postgres-read-1"
			instance_class = "db.t4g.micro"
		}
	]
}

output "postgres_read_replica_endpoints" {
	value = module.postgres_with_replica.read_replica_endpoints
}
```

Read replicas replicate asynchronously, so their data can lag behind the primary. The module requires automated backups for this configuration.

### Multi-AZ DB Instance With Failover-Only Standby

One primary plus an RDS-managed synchronous standby in another Availability Zone. The standby exists for automatic failover only; it does not provide read capacity or a separate endpoint:

```hcl
module "postgres_multi_az" {
	source = "../../modules/rds-postgres"

	identifier                  = "app-postgres-ha"
	deployment_mode             = "db_instance"
	multi_az                    = true
	instance_class              = "db.t4g.micro"
	master_username             = "postgres"
	manage_master_user_password = true
	vpc_id                      = var.vpc_id
	subnet_ids                  = var.private_subnet_ids
}
```

Applications connect to `module.postgres_multi_az.db_instance_endpoint`. RDS keeps that endpoint stable and redirects it to the promoted standby during failover.

For a writer plus two readable nodes, use `deployment_mode = "multi_az_cluster"` instead. That is a distinct architecture with the class, three-AZ subnet, backup, and migration requirements described above.

## Requirements

- Terraform with support for resource lifecycle preconditions.
- AWS provider with support for `aws_db_instance.manage_master_user_password` and `master_user_secret` (AWS provider 6.66.0 is supported).
- An AWS provider configuration and permissions to manage the selected RDS and, when enabled, security group resources.

## Credentials

Choose exactly one master-password mode:

- **User-supplied password**: `manage_master_user_password` is `false` (the default) and `master_password` must be supplied. Mark the input sensitive and avoid committing plaintext credentials.
- **RDS-managed password**: set `manage_master_user_password` to `true` and omit `master_password`. RDS generates and manages the password in AWS Secrets Manager. The module exposes the secret ARN, not the password.

The module rejects configurations that supply both modes or neither mode.

## Monitoring And Logs

Set `monitoring_interval` to `1`, `5`, `10`, `15`, `30`, or `60` seconds to enable RDS Enhanced Monitoring. By default, the module creates the standard RDS monitoring IAM role and attaches the AWS-managed `AmazonRDSEnhancedMonitoringRole` policy. Set `create_monitoring_role = false` and provide `monitoring_role_arn` to use an existing role.

Set `cloudwatch_log_exports` to any combination of `postgresql`, `upgrade`, and `iam-db-auth-error`. The module creates matching CloudWatch log groups and applies `cloudwatch_log_retention_in_days`.

## Backups, Snapshots, And Replicas

Set `backups_enabled` to control automated backups; when false, the effective retention period is zero. Read replicas require automated backups to be enabled. `read_replicas` creates same-region replicas with the primary DB's subnet group and security groups.

Use `copy_tags_to_snapshot` to copy instance tags to snapshots. `snapshot_identifier` optionally restores the instance from an existing snapshot. The existing `skip_final_snapshot` and `final_snapshot_identifier` inputs control the final snapshot at destroy time.

### Restore a DB instance from a snapshot

For `deployment_mode = "db_instance"`, `snapshot_identifier` is passed to the RDS DB instance resource to restore a new instance from an existing DB snapshot. Use a new, unique `identifier` when creating a parallel restore; changing the snapshot identifier on an already-managed instance can cause Terraform to replace that instance. The snapshot must be a compatible PostgreSQL DB snapshot in the target Region. For an encrypted snapshot, the restore needs access to its KMS key; copy the snapshot to the target Region first if necessary.

The restored database contains the snapshot's data and master-user credentials. RDS's PostgreSQL snapshot-restore API does not support turning on Secrets Manager-managed master credentials as part of the restore request. Although this module exposes `snapshot_identifier`, its current credential precondition requires either managed credentials or a non-null caller-supplied password, so PostgreSQL snapshot restore is not currently supported end-to-end by the module's managed-password configuration. Do not set `manage_master_user_password = true` for a snapshot restore with this version of the module. The credential flow must be adjusted to restore with the snapshot's existing credentials and enable RDS-managed credentials afterward, or the restore must be done outside this module.

Set `snapshot_export_configuration` to export a specified existing snapshot to S3. This is a one-off export task, not continuous replication. The caller must provide a snapshot ARN, S3 bucket, KMS key, and IAM role with the required RDS, S3, and KMS permissions. Leave it `null` when no export is requested.

## Parameters And Alarms

Pass `postgres_parameters` and `parameter_group_family` to have the module create and attach a PostgreSQL DB parameter group. Alternatively, set `parameter_group_name` to use an existing group; the two approaches cannot be combined.

`cloudwatch_alarms` accepts a list of metric alarm definitions. Each alarm is dimensioned to the primary DB instance by default; optional dimensions are merged with the primary instance identifier. Provide `alarm_actions` or `ok_actions` to route notifications, such as to an SNS topic.

### RDS-managed password example

```hcl
module "postgres" {
	source = "../../modules/rds-postgres"

	identifier     = "app-postgres"
	engine_version = "18.4"
	instance_class = "db.t4g.micro"

	master_username              = "postgres"
	manage_master_user_password = true

	vpc_id     = var.vpc_id
	subnet_ids = var.private_subnet_ids

	database_name = "app"
}

output "postgres_master_secret_arn" {
	value = module.postgres.master_user_secret_arn
}
```

### User-supplied password example

```hcl
variable "db_password" {
	type      = string
	sensitive = true
}

module "postgres" {
	source = "../../modules/rds-postgres"

	identifier     = "app-postgres"
	engine_version = "18.4"
	instance_class = "db.t4g.micro"

	master_username = "postgres"
	master_password = var.db_password

	vpc_id     = var.vpc_id
	subnet_ids = var.private_subnet_ids

	database_name = "app"
}
```

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `identifier` | `string` | Required | Unique DB instance identifier. |
| `master_username` | `string` | Required | Master database username. |
| `master_password` | `string` | `null` | User-supplied password; required when managed password mode is disabled. Sensitive. |
| `manage_master_user_password` | `bool` | `false` | Let RDS generate and manage the password in Secrets Manager. Requires `master_password` to be null. |
| `vpc_id` | `string` | Required | Existing VPC ID, used when creating a security group. |
| `subnet_ids` | `list(string)` | Required | Existing subnet IDs for the DB subnet group, normally across multiple AZs. |
| `engine_version` | `string` | `18.4` | PostgreSQL engine version. |
| `instance_class` | `string` | `db.t4g.micro` | DB instance class. |
| `allocated_storage` | `number` | `20` | Initial storage in GiB. |
| `max_allocated_storage` | `number` | `100` | Autoscaling storage maximum in GiB; `0` disables autoscaling. |
| `storage_type` | `string` | `gp3` | RDS storage type. |
| `storage_encrypted` | `bool` | `true` | Enable storage encryption. |
| `kms_key_id` | `string` | `null` | Optional storage encryption KMS key ARN or ID. |
| `database_name` | `string` | `null` | Initial database name. |
| `port` | `number` | `5432` | PostgreSQL port. |
| `publicly_accessible` | `bool` | `false` | Whether the DB instance has a public endpoint. |
| `iam_database_authentication_enabled` | `bool` | `false` | Enable IAM database authentication. |
| `monitoring_interval` | `number` | `0` | Enhanced Monitoring interval in seconds; `0` disables monitoring. |
| `create_monitoring_role` | `bool` | `true` | Create the standard IAM role required for Enhanced Monitoring. |
| `monitoring_role_arn` | `string` | `null` | Existing monitoring role ARN when role creation is disabled. |
| `cloudwatch_log_exports` | `list(string)` | `[]` | PostgreSQL log types to export: `postgresql`, `upgrade`, and/or `iam-db-auth-error`. |
| `cloudwatch_log_retention_in_days` | `number` | `30` | Retention for created RDS CloudWatch log groups. |
| `multi_az` | `bool` | `false` | For `db_instance` mode, create a DB instance with one standby. |
| `deployment_mode` | `string` | `db_instance` | Select `db_instance` or `multi_az_cluster`. |
| `cluster_instance_class` | `string` | `null` | Supported cluster node class required for `multi_az_cluster`. |
| `backups_enabled` | `bool` | `true` | Enable automated backups; required when creating read replicas. |
| `backup_retention_period` | `number` | `7` | Automated backup retention in days; `0` disables backups. |
| `backup_window` | `string` | `03:00-04:00` | Preferred daily backup window in UTC. |
| `maintenance_window` | `string` | `sun:04:00-sun:05:00` | Preferred weekly maintenance window in UTC. |
| `deletion_protection` | `bool` | `true` | Protect the DB instance from deletion. |
| `skip_final_snapshot` | `bool` | `false` | Skip the final snapshot when destroying the DB instance. |
| `final_snapshot_identifier` | `string` | `null` | Identifier for the final snapshot. |
| `copy_tags_to_snapshot` | `bool` | `true` | Copy DB instance tags to snapshots. |
| `snapshot_identifier` | `string` | `null` | Optional snapshot ID or ARN to restore from. |
| `apply_immediately` | `bool` | `false` | Apply modifications immediately. |
| `auto_minor_version_upgrade` | `bool` | `true` | Automatically apply minor engine upgrades. |
| `allow_major_version_upgrade` | `bool` | `false` | Allow major engine upgrades. |
| `parameter_group_name` | `string` | `null` | Optional existing DB parameter group. |
| `parameter_group_family` | `string` | `null` | Family for a module-created parameter group, required when `postgres_parameters` is non-empty. |
| `postgres_parameters` | `list(object)` | `[]` | PostgreSQL parameter group settings; creates a parameter group when non-empty. |
| `option_group_name` | `string` | `null` | Optional existing DB option group. |
| `read_replicas` | `list(object)` | `[]` | Optional same-region read replicas; requires backups enabled. |
| `cloudwatch_alarms` | `list(object)` | `[]` | CloudWatch metric alarms to create for the primary instance. |
| `snapshot_export_configuration` | `object` | `null` | Optional configuration for exporting an existing snapshot to S3. |
| `create_security_group` | `bool` | `true` | Create and associate a security group. |
| `security_group_name` | `string` | `null` | Name prefix for the created security group. |
| `security_group_description` | `string` | `Security group for PostgreSQL RDS instance` | Description for the created security group. |
| `security_group_ids` | `list(string)` | `[]` | Existing security group IDs when `create_security_group` is `false`. |
| `security_group_ingress_rules` | `list(object)` | `[]` | Ingress rules for the created security group. Each rule supports `description`, `from_port`, `to_port`, `ip_protocol`, `cidr_ipv4`, `cidr_ipv6`, and `referenced_security_group_id`. |
| `security_group_egress_rules` | `list(object)` | `[]` | Egress rules for the created security group, with the same fields as ingress rules. |
| `tags` | `map(string)` | `{}` | Tags applied to the DB instance, subnet group, and created security group. |

## Outputs

| Name | Description |
| --- | --- |
| `db_instance_id` | RDS DB instance identifier or cluster identifier. |
| `db_instance_arn` | RDS DB instance ARN or cluster ARN. |
| `db_instance_endpoint` | Writer DB endpoint including port. |
| `db_instance_address` | Writer DB DNS address. |
| `db_instance_port` | PostgreSQL port. |
| `db_instance_status` | Current DB instance status; `null` in cluster mode. |
| `db_instance_resource_id` | AWS RDS DB instance or DB cluster resource ID. |
| `db_cluster_identifier` | Multi-AZ DB cluster identifier, or `null` in DB instance mode. |
| `db_cluster_reader_endpoint` | Cluster reader endpoint, or `null` in DB instance mode. |
| `master_user_secret_arn` | ARN of the RDS-managed Secrets Manager secret; `null` for a user-supplied password. |
| `monitoring_role_arn` | IAM role ARN used for Enhanced Monitoring, or `null` when disabled. |
| `cloudwatch_log_group_names` | Names of created CloudWatch log groups for RDS logs. |
| `parameter_group_name` | Custom or supplied DB parameter group name, or `null` when the default is used. |
| `read_replica_endpoints` | Map of read replica identifiers to connection endpoints. |
| `cloudwatch_alarm_arns` | Map of CloudWatch alarm names to ARNs. |
| `snapshot_export_task_id` | Snapshot export task identifier, or `null` when export is not configured. |
| `snapshot_export_task_status` | Export task status, or `null` when export is not configured. |
| `db_subnet_group_name` | DB subnet group name. |
| `db_subnet_group_arn` | DB subnet group ARN. |
| `security_group_id` | Created security group ID, or the first supplied ID when using existing groups. |
| `security_group_ids` | All security group IDs associated with the DB instance. |
