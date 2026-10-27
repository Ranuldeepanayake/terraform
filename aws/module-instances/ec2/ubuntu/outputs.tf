output "instance_id" {
  description = "Ubuntu EC2 instance ID."
  value       = module.ec2.instance_id
}

output "instance_state" {
  description = "Ubuntu EC2 instance lifecycle state."
  value       = module.ec2.instance_state
}

output "ami_id" {
  description = "Ubuntu AMI ID used by the instance."
  value       = module.ec2.ami_id
}

output "private_ip" {
  description = "Ubuntu EC2 private IPv4 address."
  value       = module.ec2.private_ip
}

output "public_ip" {
  description = "Ubuntu EC2 public IPv4 address, if assigned."
  value       = module.ec2.public_ip
}

output "availability_zone" {
  description = "Availability Zone containing the Ubuntu instance."
  value       = module.ec2.availability_zone
}

output "iam_instance_profile_name" {
  description = "IAM instance profile attached to the Ubuntu instance."
  value       = module.ec2.iam_instance_profile_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name, or null when logging is disabled."
  value       = module.ec2.cloudwatch_log_group_name
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarms created for the Ubuntu instance."
  value       = module.ec2.cloudwatch_alarms
}
