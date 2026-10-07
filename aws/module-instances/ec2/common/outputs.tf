# Instance details
output "instance_id" {
  description = "EC2 instance ID."
  value       = module.ec2.instance_id
}

output "instance_arn" {
  description = "EC2 instance ARN."
  value       = module.ec2.instance_arn
}

output "instance_state" {
  description = "Current EC2 instance lifecycle state."
  value       = module.ec2.instance_state
}

output "ami_id" {
  description = "AMI ID used by the instance."
  value       = module.ec2.ami_id
}

output "instance_type" {
  description = "Instance type used by the instance."
  value       = module.ec2.instance_type
}

output "ipv6_only" {
  description = "Whether the instance was configured for IPv6-only networking."
  value       = module.ec2.ipv6_only
}

output "detailed_monitoring_enabled" {
  description = "Whether detailed EC2 monitoring is enabled."
  value       = module.ec2.detailed_monitoring_enabled
}

output "private_ip" {
  description = "EC2 private IPv4 address."
  value       = module.ec2.private_ip
}

output "private_dns" {
  description = "EC2 private DNS name."
  value       = module.ec2.private_dns
}

output "public_ip" {
  description = "EC2 public IPv4 address, if assigned."
  value       = module.ec2.public_ip
}

output "public_dns" {
  description = "EC2 public DNS name, if assigned."
  value       = module.ec2.public_dns
}

output "availability_zone" {
  description = "Availability Zone containing the instance."
  value       = module.ec2.availability_zone
}

output "subnet_id" {
  description = "Subnet containing the instance."
  value       = module.ec2.subnet_id
}

# Network and storage
output "security_group_ids" {
  description = "Security groups attached to the instance."
  value       = module.ec2.security_group_ids
}

output "created_security_group_id" {
  description = "ID of the security group created by the module, if any."
  value       = module.ec2.created_security_group_id
}

output "created_security_group_arn" {
  description = "ARN of the security group created by the module, if any."
  value       = module.ec2.created_security_group_arn
}

output "created_security_group_name" {
  description = "Name of the security group created by the module, if any."
  value       = module.ec2.created_security_group_name
}

output "key_pair_name" {
  description = "Key pair name selected for the instance."
  value       = module.ec2.key_pair_name
}

output "created_key_pair_name" {
  description = "Name of the key pair created by the module, if any."
  value       = module.ec2.created_key_pair_name
}

output "created_key_pair_fingerprint" {
  description = "Fingerprint of a key pair created by the module, if any."
  value       = module.ec2.created_key_pair_fingerprint
}

output "root_volume_id" {
  description = "ID of the root EBS volume."
  value       = module.ec2.root_volume_id
}

output "ebs_volume_ids" {
  description = "Map of configured additional EBS volume names to IDs."
  value       = module.ec2.ebs_volume_ids
}

output "ebs_volume_attachments" {
  description = "Map of additional EBS volume attachment details."
  value       = module.ec2.ebs_volume_attachments
}

# IAM
output "iam_role_arn" {
  description = "IAM role ARN selected for the instance."
  value       = module.ec2.iam_role_arn
}

output "iam_role_name" {
  description = "IAM role name selected for the instance profile."
  value       = module.ec2.iam_role_name
}

output "iam_role_created" {
  description = "Whether the caller created the IAM role."
  value       = module.ec2.iam_role_created
}

output "iam_role_unique_id" {
  description = "Unique ID of the selected IAM role, when available."
  value       = module.ec2.iam_role_unique_id
}

output "iam_instance_profile_name" {
  description = "Name of the instance profile attached to the instance."
  value       = module.ec2.iam_instance_profile_name
}

output "iam_instance_profile_arn" {
  description = "Instance profile ARN attached to the instance."
  value       = module.ec2.iam_instance_profile_arn
}

output "iam_instance_profile_id" {
  description = "ID of the instance profile attached to the instance."
  value       = module.ec2.iam_instance_profile_id
}

output "iam_instance_profile_created" {
  description = "Whether the caller created the instance profile."
  value       = module.ec2.iam_instance_profile_created
}

# Monitoring and alerts
output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name, or null when logging is disabled."
  value       = module.ec2.cloudwatch_log_group_name
}

output "cloudwatch_logging_enabled" {
  description = "Whether CloudWatch log shipping is enabled."
  value       = module.ec2.cloudwatch_logging_enabled
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN, or null when logging is disabled."
  value       = module.ec2.cloudwatch_log_group_arn
}

output "cloudwatch_alarm_names" {
  description = "CloudWatch alarm names created by the module."
  value       = module.ec2.cloudwatch_alarm_names
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names and ARNs keyed by alarm type."
  value       = module.ec2.cloudwatch_alarms
}

output "cloudwatch_agent_enabled" {
  description = "Whether the CloudWatch Agent is installed for logs or metrics."
  value       = module.ec2.cloudwatch_agent_enabled
}

output "setup_script_configured" {
  description = "Whether caller-provided setup commands are configured."
  value       = module.ec2.setup_script_configured
}

output "alarm_email_topic_arn" {
  description = "SNS topic ARN used for alarm email notifications, or null when no email addresses are configured."
  value       = module.ec2.alarm_email_topic_arn
}

output "alarm_email_subscription_arns" {
  description = "SNS email subscription ARNs, which may be pending confirmation."
  value       = module.ec2.alarm_email_subscription_arns
}

output "alarm_email_addresses" {
  description = "Email addresses configured for alarm notifications."
  value       = module.ec2.alarm_email_addresses
}
