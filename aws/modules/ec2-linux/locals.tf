locals {
  # Reuse one generated suffix so resource names and tags stay consistent.
  random_suffix = random_string.suffix.result

  # Resolve network placement and the selected Linux image.
  availability_zone = coalesce(var.availability_zone, data.aws_subnet.selected.availability_zone)
  vpc_id            = coalesce(var.vpc_id, data.aws_subnet.selected.vpc_id)
  ami_id            = var.ami_id != null ? var.ami_id : data.aws_ami.linux[0].id

  # Select created or caller-provided networking and access resources.
  existing_security_group_ids = distinct(concat(
    var.security_group_ids,
    var.security_group_id == null ? [] : [var.security_group_id],
  ))
  security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : local.existing_security_group_ids
  key_name           = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_name

  # Determine role availability from input choices so resource counts are plan-time known.
  iam_role_selected = (
    var.create_iam_role ||
    (var.create_instance_profile && var.existing_iam_role_name != null) ||
    (!var.create_instance_profile && var.existing_instance_profile_name != null)
  )

  # Resolve the selected role and profile names and ARN values.
  iam_role_name = var.create_iam_role ? try(aws_iam_role.this[0].name, null) : (
    var.create_instance_profile ?
    try(data.aws_iam_role.existing[0].name, null) :
    try(data.aws_iam_instance_profile.existing[0].role_name, null)
  )
  iam_role_arn = var.create_iam_role ? try(aws_iam_role.this[0].arn, null) : (
    var.create_instance_profile ?
    try(data.aws_iam_role.existing[0].arn, null) :
    try(data.aws_iam_instance_profile.existing[0].role_arn, null)
  )
  iam_instance_profile_name = var.create_instance_profile ? (
    try(aws_iam_instance_profile.this[0].name, null)
    ) : (
    try(data.aws_iam_instance_profile.existing[0].name, null)
  )

  # Enable the agent for requested logs or agent-provided metrics.
  cloudwatch_agent_enabled = var.enable_cloudwatch_logging || (
    var.alarms.enabled && (var.alarms.memory_enabled || var.alarms.disk_space_enabled)
  )
  cloudwatch_log_group_name = var.enable_cloudwatch_logging ? aws_cloudwatch_log_group.this[0].name : null

  # Use standard Linux paths when callers leave these collections unspecified.
  cloudwatch_log_files = var.cloudwatch_log_files != null ? var.cloudwatch_log_files : [
    "/var/log/messages",
    "/var/log/cloud-init-output.log",
  ]
  disk_paths = var.disk_paths != null ? var.disk_paths : ["/"]

  # Build only the CloudWatch Agent sections enabled by the caller.
  cloudwatch_agent_config = merge(
    {
      agent = {
        metrics_collection_interval = var.cloudwatch_metrics_collection_interval
        append_dimensions           = { InstanceId = "$${aws:InstanceId}" }
        aggregation_dimensions      = [["InstanceId"]]
      }
    },
    var.alarms.enabled && (var.alarms.memory_enabled || var.alarms.disk_space_enabled) ? {
      metrics = {
        namespace = "CWAgent"
        metrics_collected = merge(
          var.alarms.memory_enabled ? {
            mem = { measurement = ["mem_used_percent"] }
          } : {},
          var.alarms.disk_space_enabled ? {
            disk = {
              measurement = ["used_percent"]
              resources   = local.disk_paths
            }
          } : {},
        )
      }
    } : {},
    var.enable_cloudwatch_logging ? {
      logs = {
        logs_collected = {
          files = {
            collect_list = [
              for path in local.cloudwatch_log_files : {
                file_path       = path
                log_group_name  = local.cloudwatch_log_group_name
                log_stream_name = "{instance_id}"
              }
            ]
          }
        }
      }
    } : {},
  )

  # Add the optional email topic to caller-provided alarm actions.
  email_alarm_topic_arn = try(aws_sns_topic.alarm_email[0].arn, null)
  effective_alarm_actions = distinct(concat(
    var.alarm_actions,
    local.email_alarm_topic_arn == null ? [] : [local.email_alarm_topic_arn],
  ))

  # Enable each built-in alarm only when both switches allow it.
  alarms = {
    cpu_enabled         = var.alarms.enabled && var.alarms.cpu_enabled
    memory_enabled      = var.alarms.enabled && var.alarms.memory_enabled
    disk_space_enabled  = var.alarms.enabled && var.alarms.disk_space_enabled
    network_in_enabled  = var.alarms.enabled && var.alarms.network_in_enabled
    network_out_enabled = var.alarms.enabled && var.alarms.network_out_enabled
    ebs_io_enabled      = var.alarms.enabled && var.alarms.ebs_io_enabled
  }

  # Resolve IDs for new and existing EBS volumes.
  volume_ids = {
    for name, volume in var.ebs_volumes :
    name => (volume.volume_id != null ? volume.volume_id : aws_ebs_volume.this[name].id)
  }

  # Default mounted volumes to ext4 and format only newly created volumes.
  volume_filesystems = {
    for name, volume in var.ebs_volumes :
    name => coalesce(volume.filesystem, "ext4")
  }

  # Respect an explicit formatting choice when one is supplied.
  volume_should_format = {
    for name, volume in var.ebs_volumes :
    name => (volume.format_on_mount == null ? volume.volume_id == null : volume.format_on_mount)
  }

  # Generate Linux commands to mount volumes only when a mount path is configured.
  volume_mount_commands = [
    for name, volume in var.ebs_volumes : <<-BASH
      VOLUME_ID="${replace(local.volume_ids[name], "-", "")}"
      DEVICE="/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol$VOLUME_ID"
      FALLBACK_DEVICE="${volume.device_name}"
      until [ -b "$DEVICE" ] || [ -b "$FALLBACK_DEVICE" ]; do sleep 5; done
      if [ ! -b "$DEVICE" ]; then DEVICE="$FALLBACK_DEVICE"; fi
      mkdir -p "${volume.mount_path}"
      if [ "${local.volume_should_format[name]}" = "true" ] && ! blkid "$DEVICE" >/dev/null 2>&1; then
        if [ "${local.volume_filesystems[name]}" = "xfs" ]; then dnf install -y xfsprogs; fi
        mkfs -t "${local.volume_filesystems[name]}" "$DEVICE"
      fi
      UUID=$(blkid -s UUID -o value "$DEVICE")
      if [ -z "$UUID" ]; then echo "No filesystem found on attached EBS volume; refusing to format it automatically" >&2; exit 1; fi
      grep -qF "UUID=$UUID " /etc/fstab || echo "UUID=$UUID ${volume.mount_path} ${local.volume_filesystems[name]} defaults,nofail 0 2" >> /etc/fstab
      mount "${volume.mount_path}"
    BASH
    if volume.mount_path != null
  ]

  # Expand each configured volume into read and write operation alarm dimensions.
  ebs_io_alarm_pairs = flatten([
    for name, volume_id in local.volume_ids : [
      for metric_name in ["VolumeReadOps", "VolumeWriteOps"] : {
        key         = "${name}-${lower(replace(metric_name, "Volume", ""))}"
        volume_id   = volume_id
        metric_name = metric_name
      }
    ]
  ])

  # Bootstrap the Linux instance with SSM, requested volumes, CloudWatch, and caller commands.
  user_data = <<BASH
#!/bin/bash
set -euo pipefail

if ! command -v amazon-ssm-agent >/dev/null 2>&1; then dnf install -y amazon-ssm-agent; fi
systemctl enable --now amazon-ssm-agent

${join("\n", local.volume_mount_commands)}

${local.cloudwatch_agent_enabled ? <<-CWAGENT
dnf install -y amazon-cloudwatch-agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CW_CONFIG'
${jsonencode(local.cloudwatch_agent_config)}
CW_CONFIG
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
CWAGENT
: ""}

${var.setup_script != null ? var.setup_script : ""}
BASH
}
