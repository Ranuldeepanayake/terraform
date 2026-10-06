output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.ec2.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance."
  value       = aws_instance.ec2.arn
}

output "instance_state" {
  description = "Current lifecycle state of the EC2 instance."
  value       = aws_instance.ec2.instance_state
}

output "instance_type" {
  description = "Instance type used by the EC2 instance."
  value       = aws_instance.ec2.instance_type
}

output "ipv6_only" {
  description = "Whether the instance was configured for IPv6-only networking."
  value       = var.ipv6_only
}

output "ami_id" {
  description = "AMI ID used by the EC2 instance."
  value       = aws_instance.ec2.ami
}

output "private_ip" {
  description = "Private IPv4 address of the EC2 instance."
  value       = aws_instance.ec2.private_ip
}

output "private_dns" {
  description = "Private DNS name of the EC2 instance."
  value       = aws_instance.ec2.private_dns
}

output "public_ip" {
  description = "Public IPv4 address, if one was assigned."
  value       = aws_instance.ec2.public_ip
}

output "public_dns" {
  description = "Public DNS name, if one was assigned."
  value       = aws_instance.ec2.public_dns
}

output "ipv6_addresses" {
  description = "IPv6 addresses assigned to the EC2 instance."
  value       = aws_instance.ec2.ipv6_addresses
}

output "availability_zone" {
  description = "Availability Zone of the EC2 instance."
  value       = aws_instance.ec2.availability_zone
}

output "placement_group" {
  description = "Placement group of the EC2 instance, or null when none is configured."
  value       = aws_instance.ec2.placement_group
}

output "subnet_id" {
  description = "Subnet containing the EC2 instance."
  value       = aws_instance.ec2.subnet_id
}

output "vpc_security_group_ids" {
  description = "Security group IDs attached to the instance (alias for security_group_ids)."
  value       = aws_instance.ec2.vpc_security_group_ids
}

output "created_security_group_id" {
  description = "ID of the security group created by this module, or null when using existing groups."
  value       = try(aws_security_group.this[0].id, null)
}

output "created_security_group_name" {
  description = "Name of the security group created by this module, or null when using existing groups."
  value       = try(aws_security_group.this[0].name, null)
}

output "created_security_group_arn" {
  description = "ARN of the security group created by this module, or null when using existing groups."
  value       = try(aws_security_group.this[0].arn, null)
}

output "root_volume_id" {
  description = "ID of the instance root EBS volume."
  value       = try(aws_instance.ec2.root_block_device[0].volume_id, null)
}

output "root_block_device" {
  description = "Computed root block-device details, including volume ID, size, type, and encryption state."
  value       = try(aws_instance.ec2.root_block_device[0], null)
}

output "ebs_block_devices" {
  description = "Computed additional block-device mappings attached to the EC2 instance."
  value       = aws_instance.ec2.ebs_block_device
}

output "security_group_ids" {
  description = "Security group IDs attached to the instance."
  value       = aws_instance.ec2.vpc_security_group_ids
}

output "created_key_pair_name" {
  description = "Name of the key pair created by this module, or null when using an existing or no key pair."
  value       = try(aws_key_pair.this[0].key_name, null)
}

output "key_pair_name" {
  description = "Key pair name selected for the instance, whether created, existing, or null."
  value       = aws_instance.ec2.key_name
}

output "created_key_pair_fingerprint" {
  description = "Fingerprint of the key pair created by this module, or null otherwise."
  value       = try(aws_key_pair.this[0].fingerprint, null)
}

output "key_name" {
  description = "EC2 key pair name, or null when no key pair was selected."
  value       = aws_instance.ec2.key_name
}

output "iam_role_name" {
  description = "Name of the IAM role attached to the instance."
  value       = local.iam_role_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the instance."
  value       = local.iam_role_arn
}

output "iam_role_unique_id" {
  description = "Unique ID of the IAM role selected for the instance, when available."
  value = var.create_iam_role ? (
    try(aws_iam_role.this[0].unique_id, null)
    ) : (
    var.create_instance_profile ? try(data.aws_iam_role.existing[0].unique_id, null) : null
  )
}

output "iam_role_created" {
  description = "Whether this module created the IAM role."
  value       = var.create_iam_role
}

output "iam_instance_profile_name" {
  description = "Name of the instance profile attached to the instance."
  value       = local.iam_instance_profile_name
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile attached to the instance."
  value = var.create_instance_profile ? (
    try(aws_iam_instance_profile.this[0].arn, null)
    ) : (
    try(data.aws_iam_instance_profile.existing[0].arn, null)
  )
}

output "iam_instance_profile_id" {
  description = "ID of the instance profile attached to the instance."
  value = var.create_instance_profile ? (
    try(aws_iam_instance_profile.this[0].id, null)
    ) : (
    try(data.aws_iam_instance_profile.existing[0].id, null)
  )
}

output "iam_instance_profile_created" {
  description = "Whether this module created the instance profile."
  value       = var.create_instance_profile
}

output "ebs_volume_ids" {
  description = "Map of configured additional EBS volume names to volume IDs."
  value       = local.volume_ids
}

output "ebs_volume_attachments" {
  description = "Map of additional volume keys to attached volume IDs and device names."
  value = {
    for name, attachment in aws_volume_attachment.this : name => {
      volume_id   = attachment.volume_id
      device_name = attachment.device_name
    }
  }
}

output "cloudwatch_log_group_name" {
  description = "Created CloudWatch log group name, or null when logging is disabled."
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the created CloudWatch log group, or null when logging is disabled."
  value       = try(aws_cloudwatch_log_group.this[0].arn, null)
}

output "cloudwatch_logging_enabled" {
  description = "Whether CloudWatch log shipping is enabled."
  value       = var.enable_cloudwatch_logging
}

output "cloudwatch_agent_enabled" {
  description = "Whether CloudWatch Agent installation is enabled for logs or memory/disk metrics."
  value       = local.cloudwatch_agent_enabled
}

output "detailed_monitoring_enabled" {
  description = "Whether EC2 detailed monitoring is enabled."
  value       = aws_instance.ec2.monitoring
}

output "setup_script_configured" {
  description = "Whether a caller-supplied setup script is included in user data."
  value       = var.setup_script != null && trimspace(var.setup_script) != ""
}

output "alarm_email_topic_arn" {
  description = "SNS topic ARN used for alarm email notifications, or null when no email addresses are configured."
  value       = try(aws_sns_topic.alarm_email[0].arn, null)
}

output "alarm_email_subscription_arns" {
  description = "Map of configured email recipients to SNS subscription ARNs, which may be pending confirmation."
  value = {
    for email, subscription in aws_sns_topic_subscription.alarm_email :
    email => subscription.arn
  }
}

output "alarm_email_addresses" {
  description = "Configured email addresses subscribed to the alarm SNS topic."
  value       = sort(tolist(var.alarm_email_addresses))
}

output "cloudwatch_alarms" {
  description = "Map of all created CloudWatch alarm keys to their names and ARNs."
  value = merge(
    {
      for alarm in aws_cloudwatch_metric_alarm.cpu :
      "cpu" => { name = alarm.alarm_name, arn = alarm.arn }
    },
    {
      for alarm in aws_cloudwatch_metric_alarm.memory :
      "memory" => { name = alarm.alarm_name, arn = alarm.arn }
    },
    {
      for alarm in aws_cloudwatch_metric_alarm.disk_space :
      "disk_space" => { name = alarm.alarm_name, arn = alarm.arn }
    },
    {
      for alarm in aws_cloudwatch_metric_alarm.network_in :
      "network_in" => { name = alarm.alarm_name, arn = alarm.arn }
    },
    {
      for alarm in aws_cloudwatch_metric_alarm.network_out :
      "network_out" => { name = alarm.alarm_name, arn = alarm.arn }
    },
    {
      for key, alarm in aws_cloudwatch_metric_alarm.ebs_io :
      "ebs_io_${key}" => { name = alarm.alarm_name, arn = alarm.arn }
    },
    {
      for key, alarm in aws_cloudwatch_metric_alarm.additional :
      "additional_${key}" => { name = alarm.alarm_name, arn = alarm.arn }
    },
  )
}

output "cloudwatch_alarm_names" {
  description = "Names of CloudWatch alarms created by the module."
  value = concat(
    aws_cloudwatch_metric_alarm.cpu[*].alarm_name,
    aws_cloudwatch_metric_alarm.memory[*].alarm_name,
    aws_cloudwatch_metric_alarm.disk_space[*].alarm_name,
    aws_cloudwatch_metric_alarm.network_in[*].alarm_name,
    aws_cloudwatch_metric_alarm.network_out[*].alarm_name,
    [for alarm in values(aws_cloudwatch_metric_alarm.ebs_io) : alarm.alarm_name],
    [for alarm in values(aws_cloudwatch_metric_alarm.additional) : alarm.alarm_name],
  )
}
