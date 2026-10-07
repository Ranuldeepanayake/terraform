# EC2 instance module

Creates an Amazon Linux 2023 EC2 instance with an IAM instance profile, Systems Manager access, configurable networking and storage, and optional CloudWatch logging and alarms.

## Features

- Configurable AMI, instance type, subnet, public IP, IPv6-only networking, IMDSv2, and root EBS disk.
- Either create a security group with explicit ingress/egress rules or attach existing security group IDs.
- Either create an EC2 key pair from a caller-supplied public key, use an existing key pair, or omit a key pair and manage the instance through Systems Manager.
- An instance role with `AmazonSSMManagedInstanceCore` is always attached. Amazon Linux user data ensures the SSM agent is installed, enabled, and started.
- IAM role and instance profile can each be created by the module or reused from the account.
- Optionally create and attach additional encrypted EBS volumes, or attach existing EBS volume IDs. Linux filesystems can be mounted at a path.
- Optionally create a CloudWatch log group and ship configured Linux log files using the CloudWatch agent.
- Optionally create CPU, memory, disk utilization, network-in/network-out traffic, and per-volume EBS read/write operation alarms.
- Accept caller-defined additional CloudWatch metric alarms.
- Accept an optional caller-supplied Bash setup script, run as root after the module's bootstrap.
- Optional EC2 detailed monitoring and configurable resource tags.
- Bootstrap changes replace the instance by default so agent and volume mount configuration is rerun; this can be disabled with `user_data_replace_on_change` when replacement is not acceptable.

## Requirements and assumptions

- Terraform 1.6 or later, AWS provider 5.x or 6.x, and Random provider 3.x.
- When `ami_id` is null, the module selects the latest Amazon Linux 2023 x86_64 AMI. A custom `ami_id` must be compatible with the Linux user-data bootstrap (`dnf`, systemd, and Linux storage tools).
- The subnet must be in the same Availability Zone as any existing EBS volumes. New EBS volumes are created in the subnet's Availability Zone.
- The instance needs network access to AWS Systems Manager and, when enabled, CloudWatch endpoints, either directly or through VPC endpoints.
- IPv6-only mode requires an IPv6-native subnet and an instance type/AMI that support IPv6. The subnet's routing and DNS must provide access to any required services, such as Systems Manager and CloudWatch; IPv4 public-IP association is disabled automatically.
- Creating a key pair requires an OpenSSH public key. AWS imports that public key; you must keep and protect its matching private key to authenticate SSH connections. The module does not generate or export the private key, avoiding storing it in Terraform state. Alternatively, use an existing key pair with `key_name` or connect through Systems Manager without a key pair.
- Attaching an existing EBS volume does not transfer ownership to the module; Terraform manages only the attachment. Newly created volumes with a `mount_path` are formatted when empty by default; existing volumes are not. Formatting only happens when no filesystem is detected.
- Memory and disk alarms use CloudWatch agent metrics (additional CloudWatch charges may apply). EBS read/write alarms cover additional volumes in `ebs_volumes`; they do not include the root volume.

## Included caller

A ready-to-edit caller is provided in [`aws/module-instances/ec2/common`](../../module-instances/ec2/common). In its `main.tf`, deployment settings are passed directly as module arguments; only the AWS region and shared tags are declared in `locals`. Before use:

- Replace the subnet ID and adjust the AWS region, instance name/type, tags, and storage for your environment.
- The example caller creates a security group, IAM role, and instance profile; enables public IPv4 and assigns one IPv6 address for dual-stack networking; and imports its configured public key as an EC2 key pair.
- The example caller permits SSH from all IPv4 and IPv6 addresses. Restrict `security_group_ingress_rules` to trusted CIDRs before deployment. Opening SSH in the security group does not provide credentials; a key pair and matching private key are still required.
- CloudWatch log shipping and built-in alarms are enabled in the caller. The caller subscribes a configured email address to the module-managed SNS topic; the recipient must confirm the subscription.
- The caller includes an EC2 status-check alarm in `additional_alarms`; set it to `{}` to omit it. Its `setup_script` installs and verifies the AWS CLI on the instance. Replace the script path or contents to supply other Bash setup steps.
- For an existing security group, set `create_security_group = false` and provide `security_group_ids`. To create an instance profile around an existing role, set `create_iam_role = false` and provide `existing_iam_role_name`. To reuse an existing profile, set both `create_iam_role` and `create_instance_profile` to `false` and provide `existing_instance_profile_name`.
- Review the Terraform Cloud workspace and AWS provider profile configured in the caller's `provider.tf`, and ensure credentials and permissions are available before running Terraform.

Run Terraform from the caller directory:

```sh
terraform init
terraform validate
terraform plan
terraform apply
```

## Usage

```hcl
module "app_server" {
  source = "../../../modules/ec2-linux"

  instance_name = "app-server"
  instance_type = "t3.small"
  subnet_id     = "subnet-0123456789abcdef0"
  ipv6_only     = false
  ipv6_address_count = 1 # Assign IPv6 while retaining IPv4 (dual stack).

  # The module enables IMDSv2 and disables IMDSv1 by default.
  metadata_http_endpoint = "enabled"
  metadata_http_tokens   = "required"
  metadata_hop_limit     = 1

  # Create an instance security group. It has no ingress rules by default.
  create_security_group = true
  security_group_ingress_rules = [{
    description = "SSH from the operations network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]
  }]

  # Optional; the instance can instead be accessed using AWS Systems Manager.
  key_name = "existing-ec2-key"

  root_volume_size      = 30
  root_volume_encrypted = true
  detailed_monitoring   = true

  ebs_volumes = {
    data = {
      device_name = "/dev/sdf"
      size        = 100
      type        = "gp3"
      mount_path  = "/data"
      filesystem  = "xfs"
    }
  }

  enable_cloudwatch_logging = true
  alarms = {
    enabled               = true
    cpu_threshold         = 75
    memory_threshold      = 85
    disk_space_threshold  = 85
    network_in_threshold  = 100000000
    network_out_threshold = 100000000
    ebs_io_threshold      = 12000
  }
  additional_alarms = {
    status_check_failed = {
      metric_name         = "StatusCheckFailed"
      namespace           = "AWS/EC2"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      period              = 300
      statistic           = "Maximum"
      threshold           = 0
      dimensions = {
        InstanceId = "__EC2_INSTANCE_ID__"
      }
    }
  }
  setup_script = file("${path.module}/scripts/setup.sh")
  alarm_email_addresses = [
    "ops@example.com",
    "on-call@example.com",
  ]
  alarm_actions = ["arn:aws:sns:ap-southeast-1:123456789012:ops-alerts"]

  tags = {
    Environment = "production"
    Application = "app"
  }
}
```

### Choosing an SSH key option

Choose exactly one of these modes:

```hcl
# Create/import a key pair from a public key; keep its matching private key.
create_key_pair = true
public_key      = file(pathexpand("~/.ssh/id_ed25519.pub"))
key_name        = null

# Use an existing EC2 key pair in the same AWS Region.
create_key_pair = false
public_key      = null
key_name        = "existing-ec2-key"

# Do not configure SSH key access; use Systems Manager instead.
create_key_pair = false
public_key      = null
key_name        = null
```

`public_key` is only used when `create_key_pair = true`; setting it while `create_key_pair = false` is invalid. An imported public key is not enough to SSH by itself: the user must have the corresponding private key. Also allow TCP port 22 from trusted client CIDRs in the security group; avoid opening SSH to all IPv4 or IPv6 sources in production.

`setup_script` is optional; pass the script contents (for example, with Terraform's `file()` function). It runs as root under Bash after SSM, configured volume mounts, and the CloudWatch agent are set up. Script changes replace the instance by default because `user_data_replace_on_change` defaults to `true`. The caller owns the script file and its dependencies.

`additional_alarms` is an optional map of CloudWatch metric-alarm definitions. Each entry supplies its metric, namespace, threshold, comparison, evaluation period, and statistic. The map key is appended to the instance name unless `alarm_name` is provided. For an alarm dimension that should resolve to this instance, use the reserved value `__EC2_INSTANCE_ID__`. Per-alarm `alarm_actions` and `ok_actions` override the module-wide lists; when omitted, the module-wide values are used.

Set `alarm_email_addresses` to create an SNS topic and subscribe the provided email addresses. The SNS topic is added as an alarm action for all built-in and additional alarms, alongside configured `alarm_actions`. AWS sends a confirmation email to each address; each recipient must confirm the subscription before receiving notifications. The topic ARN is available as `alarm_email_topic_arn`. Email notifications are sent when an alarm enters the `ALARM` state, not on recovery; use `alarm_ok_actions` if recovery notifications are also required.

| Additional alarm field | Required | Default / behavior |
|---|---|---|
| `metric_name`, `namespace` | Yes | Metric identity |
| `comparison_operator`, `threshold` | Yes | Threshold condition |
| `period`, `evaluation_periods` | Yes | Evaluation window |
| `statistic` | No | `Average` |
| `alarm_name`, `alarm_description` | No | Name defaults to `<instance-name>-<map-key>`; description defaults to a generic caller-configured message |
| `dimensions` | No | `{}`; set a dimension value to `__EC2_INSTANCE_ID__` to use the instance ID |
| `datapoints_to_alarm` | No | CloudWatch default |
| `unit`, `treat_missing_data`, `actions_enabled` | No | No unit, `missing`, `true` |
| `alarm_actions`, `ok_actions` | No | Inherit the module-level action lists |
| `tags` | No | Inherit module tags |

For existing security groups, set `create_security_group = false` and provide one or more `security_group_ids` (the former single `security_group_id` input remains available for compatibility). When creating a key pair, set `create_key_pair = true` and provide `public_key`; leave `key_name` unset. To attach an existing EBS volume, supply its ID in the volume entry:

```hcl
ebs_volumes = {
  imported_data = {
    device_name = "/dev/sdg"
    volume_id   = "vol-0123456789abcdef0"
    mount_path  = "/data"
    filesystem  = "ext4"
  }
}
```

Existing volumes with data are not formatted by default. Set `format_on_mount = true` to initialize an empty existing volume, or set it to `false` to disable formatting for a newly created volume.

### IAM role and instance profile selection

By default, the module creates both an EC2-trusted IAM role and an instance profile. To create a new profile with an existing role:

```hcl
create_iam_role             = false
existing_iam_role_name      = "shared-ec2-role"
create_instance_profile     = true
iam_instance_profile_name   = "app-server-profile"
```

To reuse an existing instance profile, provide its name. The role already attached to that profile is discovered and used automatically:

```hcl
create_instance_profile        = false
create_iam_role                = false
existing_instance_profile_name = "shared-ec2-profile"
```

When reusing a profile, set `create_iam_role = false` and omit `existing_iam_role_name`: the role associated with that profile is selected automatically. By default, the module attaches `AmazonSSMManagedInstanceCore` to the selected role and attaches `CloudWatchAgentServerPolicy` when CloudWatch agent features are enabled. Set `attach_ssm_managed_policy` or `attach_cloudwatch_agent_policy` to `false` when those policies are already managed elsewhere. If using an existing role/profile without policy attachment, ensure the role trusts `ec2.amazonaws.com` and has permissions for SSM and, when enabled, CloudWatch logs/metrics.

Set `additional_iam_policy_arns` to attach caller-selected AWS-managed or customer-managed IAM policies to a newly created role. The module creates a dedicated role and instance profile for this EC2 instance and associates that profile with the instance; it does not attach that role to other instances. Supplied policies are attached as-is: review their permissions for least privilege, since broad policies can grant access beyond resources belonging to this instance. This input must be empty when reusing an existing role.

The created role trusts the EC2 service principal. The module associates its profile only with the created instance, but IAM does not prevent another authorized principal with `iam:PassRole` from attaching that profile elsewhere. Likewise, the module cannot narrow permissions granted by caller-supplied managed policies. Use least-privilege policies and restrict who can pass the role if you need stronger account-level controls.

## Inputs

| Name | Description | Default |
|---|---|---|
| `instance_name` | Base name used for module-created resources. An eight-character random suffix is appended. Must be 1-55 characters and use letters, numbers, or `+=,.@_-`. | `generic-server` |
| `ami_id` | AMI ID; null selects the latest Amazon Linux 2023 x86_64 image. | `null` |
| `instance_type` | EC2 instance type. | `t3.micro` |
| `subnet_id` | Subnet in which to launch the instance. | Required |
| `availability_zone` | Optional Availability Zone override; must match the subnet. | `null` |
| `vpc_id` | VPC for a new security group; inferred from the subnet when null. | `null` |
| `associate_public_ip_address` | Whether to associate a public IPv4 address. | `false` |
| `ipv6_only` | Use an IPv6-native subnet without IPv4 networking; disables public IPv4 association. | `false` |
| `ipv6_address_count` | Number of IPv6 addresses to assign; set for IPv6 in dual-stack mode. IPv6-only mode defaults to one. | `null` |
| `detailed_monitoring` | Enables one-minute EC2 monitoring. | `false` |
| `user_data_replace_on_change` | Replace the instance when bootstrap configuration changes. | `true` |
| `setup_script` | Caller-supplied Bash script contents appended to user data. | `null` |
| `create_iam_role` | Create a new EC2 IAM role. | `true` |
| `existing_iam_role_name` | Existing EC2-trusted role for a newly created profile. | `null` |
| `create_instance_profile` | Create a new instance profile. | `true` |
| `existing_instance_profile_name` | Existing profile to attach; its role is used automatically. | `null` |
| `attach_ssm_managed_policy` | Attach `AmazonSSMManagedInstanceCore` to the selected role. | `true` |
| `attach_cloudwatch_agent_policy` | Attach `CloudWatchAgentServerPolicy` when agent features are enabled. | `true` |
| `additional_iam_policy_arns` | Additional managed policy ARNs to attach to the newly created role; must be empty when reusing a role. | `[]` |
| `metadata_http_endpoint` | Enables or disables the instance metadata endpoint. | `enabled` |
| `metadata_http_tokens` | Controls whether IMDSv2 tokens are required (`required`) or IMDSv1 is also allowed (`optional`). | `required` |
| `metadata_hop_limit` | IMDSv2 response hop limit (1-64); increase it when containers need metadata access. | `1` |
| `create_security_group` | Create a security group instead of using existing IDs. | `false` |
| `security_group_ids` | Existing security group IDs; required when not creating one. | `[]` |
| `security_group_id` | Deprecated compatibility input for one existing security group. | `null` |
| `security_group_description` | Description for a created security group. | Terraform-defined |
| `security_group_ingress_rules` | Ingress rules for a created security group (empty by default). | `[]` |
| `security_group_egress_rules` | Egress rules for a created security group. | Allow all IPv4 |
| `create_key_pair` | Create a key pair from `public_key`. | `false` |
| `key_name` | Existing key pair name; optional when using Systems Manager only. | `null` |
| `public_key` | OpenSSH public key required to create a key pair. | `null` |
| `root_volume_type`, `root_volume_size` | Root EBS volume type and size in GiB. | `gp3`, `20` |
| `root_volume_iops`, `root_volume_throughput` | Optional root disk performance settings. | `null`, `null` |
| `root_volume_encrypted`, `root_volume_kms_key_id` | Root disk encryption controls. | `true`, `null` |
| `root_volume_delete_on_termination` | Delete the root disk on instance termination. | `true` |
| `ebs_volumes` | Map of additional new or existing volumes to attach and optionally mount. | `{}` |
| `enable_cloudwatch_logging` | Configure CloudWatch log collection. | `false` |
| `cloudwatch_log_retention_days` | Created log group retention. | `30` |
| `cloudwatch_log_kms_key_id` | Optional KMS key for the created log group. | `null` |
| `cloudwatch_log_files` | Linux log files shipped by the agent. | Messages and cloud-init output |
| `cloudwatch_metrics_collection_interval` | Agent metric collection interval in seconds. | `60` |
| `disk_paths` | Linux mount paths collected for disk utilization. | `["/"]` |
| `alarms` | Enables and configures CPU, memory, disk, network traffic, and attached-volume I/O alarms. | All disabled |
| `additional_alarms` | Map of caller-defined CloudWatch metric alarms. | `{}` |
| `alarm_email_addresses` | Email recipients for a module-managed SNS alarm topic; subscribers must confirm. | `[]` |
| `alarm_actions`, `alarm_ok_actions` | CloudWatch alarm action ARNs. | `[]` |
| `tags` | Tags for the instance and supporting resources. | `{}` |
| `timeout_create`, `timeout_update`, `timeout_delete` | EC2 resource operation timeouts. | `10m`, `15m`, `10m` |

The module creates one stable eight-character lowercase alphanumeric suffix using the Random provider and appends it to generated resource names, for example `<instance_name>-<suffix>`. The suffix is persisted in Terraform state, so names stay stable across plans. Each created component receives a `Name` tag matching its generated name; alarms and EBS volumes include descriptive components in their names and tags. These component `Name` tags take precedence over a `Name` entry in the caller's `tags` map.

The EC2 instance metadata options are configurable. Defaults enable the metadata endpoint, require IMDSv2 tokens, and set the response hop limit to `1`. Set `metadata_http_tokens = "optional"` only when workloads still require IMDSv1; increase `metadata_hop_limit` when containers need to access instance metadata.

To assign IPv6 to a dual-stack instance, set `ipv6_address_count = 1` and leave `ipv6_only = false`; IPv4 remains available according to the subnet and `associate_public_ip_address` setting. For IPv6-only networking, set `ipv6_only = true` and use an IPv6-native subnet; the module requests one IPv6 address by default and disables public IPv4 association. You can set a larger `ipv6_address_count` in either mode. Ensure the instance type and AMI support the selected networking mode and that IPv6 routing/DNS can reach required services.

The `alarms` object accepts the following fields. Alarm types default to enabled when the parent `enabled` flag is true. Numeric thresholds are in the units used by their CloudWatch metrics:

| Field | Default | Metric and statistic | Threshold units/meaning |
|---|---:|---|---|
| `enabled` | `false` | Master switch for alarms | Create built-in alarms when true |
| `cpu_enabled`, `memory_enabled`, `disk_space_enabled`, `network_in_enabled`, `network_out_enabled`, `ebs_io_enabled` | `true` each | Individually enable alarm types | Used only when `enabled = true` |
| `cpu_threshold` | `80` | `AWS/EC2 CPUUtilization` (`Average`) | CPU utilization percent (%) |
| `memory_threshold` | `80` | `CWAgent mem_used_percent` (`Average`) | Memory utilization percent (%) |
| `disk_space_threshold` | `80` | `CWAgent disk_used_percent` (`Average`) | Filesystem utilization percent (%) |
| `network_in_threshold` | `1000000000` | `AWS/EC2 NetworkIn` (`Sum`) | Inbound bytes accumulated during each period |
| `network_out_threshold` | `1000000000` | `AWS/EC2 NetworkOut` (`Sum`) | Outbound bytes accumulated during each period |
| `ebs_io_threshold` | `10000` | `AWS/EBS VolumeReadOps`/`VolumeWriteOps` (`Sum`) | Read or write operations per period, per configured additional volume |
| `period` | `300` | CloudWatch alarm period in seconds | At least 60 seconds and a multiple of 60 |
| `evaluation_periods` | `2` | Number of periods evaluated | Number of periods used to evaluate the alarm |
| `treat_missing_data` | `missing` | CloudWatch missing-data behavior | `missing`, `ignore`, `breaching`, or `notBreaching` |

All built-in threshold alarms use `GreaterThanThreshold`. Network alarms use the standard `AWS/EC2` `NetworkIn` and `NetworkOut` metrics and the `Sum` statistic; their thresholds are bytes accumulated separately for inbound and outbound traffic during each alarm period. At the default 300-second period, the default 1,000,000,000-byte threshold is about 3.33 MB/s (26.7 Mbps) averaged over the period. The included caller overrides both network thresholds to 100,000,000 bytes per 300 seconds, about 0.33 MB/s (2.67 Mbps). These are period totals, not short-lived peak-throughput limits.

The `additional_alarms.status_check_failed` example uses the `AWS/EC2 StatusCheckFailed` metric with the `Maximum` statistic and threshold `0`: a value above zero indicates a failed status check in the evaluation period. The status-check metric is a count-like 0/1 value, not a percentage.

## Outputs

| Name | Description |
|---|---|
| `instance_id`, `instance_arn` | EC2 instance identity. |
| `instance_state`, `instance_type`, `ami_id` | Instance lifecycle state, type and AMI ID used. |
| `detailed_monitoring_enabled` | Whether one-minute EC2 monitoring is enabled. |
| `private_ip`, `private_dns`, `public_ip`, `public_dns`, `ipv6_addresses` | Instance network addresses. |
| `availability_zone`, `placement_group` | Placement details for the EC2 instance. |
| `subnet_id`, `root_volume_id` | Instance subnet and root EBS volume ID. |
| `root_block_device`, `ebs_block_devices` | Computed root and additional block-device details. |
| `security_group_ids`, `vpc_security_group_ids` | Security group IDs attached to the instance. |
| `created_security_group_id`, `created_security_group_arn`, `created_security_group_name` | Created security group details, or null when existing groups are used. |
| `key_name`, `created_key_pair_name`, `created_key_pair_fingerprint` | Selected key pair and any key pair created by the module. |
| `iam_role_name`, `iam_role_arn`, `iam_role_unique_id`, `iam_role_created` | Selected role and whether the module created it. |
| `iam_instance_profile_name`, `iam_instance_profile_arn`, `iam_instance_profile_id`, `iam_instance_profile_created` | Selected profile and whether the module created it. |
| `ebs_volume_ids`, `ebs_volume_attachments` | Additional EBS volume IDs and attachment device names. |
| `cloudwatch_log_group_name`, `cloudwatch_log_group_arn`, `cloudwatch_logging_enabled` | CloudWatch log group details and logging status. |
| `cloudwatch_agent_enabled`, `setup_script_configured` | Agent and caller setup-script status. |
| `alarm_email_topic_arn`, `alarm_email_addresses`, `alarm_email_subscription_arns` | SNS topic and email subscription details; subscriptions can remain pending confirmation. |
| `cloudwatch_alarms`, `cloudwatch_alarm_names` | Alarm names and ARNs by alarm key, and a flattened list of names. |
