# Launch the Linux instance and configure its root disk and metadata service.
resource "aws_instance" "ec2" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  availability_zone           = var.availability_zone
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.ipv6_only ? false : var.associate_public_ip_address
  ipv6_address_count          = var.ipv6_only ? coalesce(var.ipv6_address_count, 1) : var.ipv6_address_count
  key_name                    = local.key_name
  vpc_security_group_ids      = local.security_group_ids
  iam_instance_profile        = local.iam_instance_profile_name
  monitoring                  = var.detailed_monitoring
  user_data                   = local.user_data
  user_data_replace_on_change = var.user_data_replace_on_change

  metadata_options {
    http_endpoint               = var.metadata_http_endpoint
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = var.metadata_hop_limit
  }

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    iops                  = var.root_volume_iops
    throughput            = var.root_volume_throughput
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_kms_key_id
    delete_on_termination = var.root_volume_delete_on_termination

    tags = merge(
      var.tags,
      {
        ResourceType = "ec2-root-volume"
        Name         = "${var.instance_name}-${local.random_suffix}-root"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "ec2-instance"
      Name         = "${var.instance_name}-${local.random_suffix}"
    }
  )

  lifecycle {
    precondition {
      condition     = !var.ipv6_only || data.aws_subnet.selected.ipv6_native
      error_message = "ipv6_only requires subnet_id to reference an IPv6-native subnet."
    }

    precondition {
      condition = (
        (var.create_security_group && length(local.existing_security_group_ids) == 0) ||
        (!var.create_security_group && length(local.existing_security_group_ids) > 0)
      )
      error_message = "Set create_security_group=true and leave existing security group IDs empty, or set create_security_group=false and provide one or more existing security group IDs."
    }

    precondition {
      condition = (
        (var.create_key_pair && var.public_key != null && var.key_name == null) ||
        (!var.create_key_pair && var.public_key == null)
      )
      error_message = "When creating a key pair, provide public_key and leave key_name unset. Otherwise leave public_key unset and optionally provide an existing key_name."
    }

    precondition {
      condition = var.create_instance_profile ? (
        (var.create_iam_role && var.existing_iam_role_name == null) ||
        (!var.create_iam_role && var.existing_iam_role_name != null)
        ) : (
        var.existing_instance_profile_name != null &&
        !var.create_iam_role &&
        var.existing_iam_role_name == null
      )
      error_message = "Create a profile with a new role or existing_iam_role_name. To reuse a profile, set create_instance_profile=false, create_iam_role=false, and existing_instance_profile_name; its associated role is used automatically."
    }

    precondition {
      condition     = !var.enable_cloudwatch_logging || length(local.cloudwatch_log_files) > 0
      error_message = "Provide at least one cloudwatch_log_files path when CloudWatch logging is enabled."
    }

    precondition {
      condition     = !(var.alarms.enabled && var.alarms.disk_space_enabled) || length(local.disk_paths) > 0
      error_message = "Provide at least one disk_paths mount point when disk-space alarms are enabled."
    }

    precondition {
      condition = alltrue([
        for volume in values(var.ebs_volumes) :
        volume.mount_path == null || (
          volume.mount_path != "/" &&
          can(regex("^/[A-Za-z0-9._/-]+$", volume.mount_path)) &&
          (volume.filesystem == null || contains(["ext4", "xfs"], volume.filesystem))
        )
      ])
      error_message = "Mounted Linux volumes require a non-root absolute path and must use ext4 or xfs."
    }
  }

  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }

  # The role policies and log group must exist before first-boot agents start.
  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy_attachment.cloudwatch_agent,
    aws_cloudwatch_log_group.this,
    aws_iam_instance_profile.this,
  ]
}

# Generate a stable eight-character suffix, matching the suffix length Terraform appends for name_prefix.
resource "random_string" "suffix" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

# Create an EC2 key pair from the caller-provided public key when requested.
resource "aws_key_pair" "this" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.instance_name}-${local.random_suffix}"
  public_key = var.public_key

  tags = merge(
    var.tags,
    {
      ResourceType = "ec2-key-pair"
      Name         = "${var.instance_name}-${local.random_suffix}"
    }
  )
}

# Create requested additional EBS volumes. Existing volume IDs are not managed here.
resource "aws_ebs_volume" "this" {
  for_each = {
    for name, volume in var.ebs_volumes : name => volume
    if volume.volume_id == null
  }

  availability_zone = local.availability_zone
  size              = each.value.size
  type              = each.value.type
  iops              = each.value.iops
  throughput        = each.value.throughput
  snapshot_id       = each.value.snapshot_id
  encrypted         = each.value.encrypted
  kms_key_id        = each.value.kms_key_id

  tags = merge(
    var.tags,
    {
      ResourceType = "ebs-volume"
      Name         = "${var.instance_name}-${each.key}-${local.random_suffix}"
    },
    each.value.tags
  )
}

# Attach new and existing additional EBS volumes to the instance.
resource "aws_volume_attachment" "this" {
  for_each = var.ebs_volumes

  device_name                    = each.value.device_name
  volume_id                      = local.volume_ids[each.key]
  instance_id                    = aws_instance.ec2.id
  force_detach                   = each.value.force_detach
  stop_instance_before_detaching = each.value.stop_instance_before_detaching
}
