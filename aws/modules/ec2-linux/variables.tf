variable "instance_name" {
  description = "Base name used as the prefix for the EC2 instance and related resources."
  type        = string
  default     = "generic-server"

  validation {
    condition = (
      length(var.instance_name) > 0 &&
      length(var.instance_name) <= 55 &&
      can(regex("^[A-Za-z0-9+=,.@_-]+$", var.instance_name))
    )
    error_message = "instance_name must be 1-55 characters and use only letters, numbers, or +=,.@_-; the IAM role name cannot exceed 64 characters after adding the separator and random suffix."
  }
}

variable "ami_id" {
  description = "AMI ID to use. When null, the latest Amazon Linux 2023 x86_64 AMI is selected."
  type        = string
  default     = null
  nullable    = true
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet in which to launch the instance. The subnet determines the VPC and, unless overridden, the Availability Zone."
  type        = string
}

variable "availability_zone" {
  description = "Optional Availability Zone override. Must match the selected subnet."
  type        = string
  default     = null
  nullable    = true
}

variable "vpc_id" {
  description = "VPC for a newly created security group. Defaults to the VPC containing subnet_id."
  type        = string
  default     = null
  nullable    = true
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IPv4 address with the instance."
  type        = bool
  default     = false
}

variable "ipv6_only" {
  description = "Launch the instance in an IPv6-native subnet without IPv4 networking."
  type        = bool
  default     = false
}

variable "ipv6_address_count" {
  description = "Number of IPv6 addresses to assign. Set this for dual-stack instances; ipv6_only assigns one by default."
  type        = number
  default     = null
  nullable    = true

  validation {
    condition = (
      var.ipv6_address_count == null ||
      (
        var.ipv6_address_count >= 1 &&
        var.ipv6_address_count == floor(var.ipv6_address_count)
      )
    )
    error_message = "ipv6_address_count must be a positive whole number when set."
  }
}

variable "detailed_monitoring" {
  description = "Enable EC2 detailed monitoring (one-minute CloudWatch metrics)."
  type        = bool
  default     = false
}

variable "user_data_replace_on_change" {
  description = "Replace the instance when bootstrap user data changes. This reapplies agent and volume mount configuration."
  type        = bool
  default     = true
}

variable "setup_script" {
  description = "Optional caller-supplied Bash commands appended to user data and executed as root after the module's SSM, volume, and CloudWatch setup."
  type        = string
  default     = null
  nullable    = true
}

variable "create_iam_role" {
  description = "Create a new EC2 IAM role. When false and creating a profile, existing_iam_role_name is required."
  type        = bool
  default     = true
}

variable "existing_iam_role_name" {
  description = "Name of an existing EC2-trusted IAM role to add to a newly created instance profile."
  type        = string
  default     = null
  nullable    = true
}

variable "create_instance_profile" {
  description = "Create a new instance profile. When false, existing_instance_profile_name is required and its attached role is used."
  type        = bool
  default     = true
}

variable "existing_instance_profile_name" {
  description = "Name of an existing instance profile to attach to the EC2 instance."
  type        = string
  default     = null
  nullable    = true
}

variable "attach_ssm_managed_policy" {
  description = "Attach AmazonSSMManagedInstanceCore to the selected role. Set false if the role already has the required permissions."
  type        = bool
  default     = true
}

variable "attach_cloudwatch_agent_policy" {
  description = "Attach CloudWatchAgentServerPolicy when the CloudWatch agent is enabled. Set false if the selected role already has the required permissions."
  type        = bool
  default     = true
}

variable "metadata_hop_limit" {
  description = "Maximum network hops for an IMDSv2 response. Increase above 1 when containers need instance metadata."
  type        = number
  default     = 1

  validation {
    condition = (
      var.metadata_hop_limit >= 1 &&
      var.metadata_hop_limit <= 64 &&
      var.metadata_hop_limit == floor(var.metadata_hop_limit)
    )
    error_message = "metadata_hop_limit must be between 1 and 64."
  }
}

variable "metadata_http_endpoint" {
  description = "Whether the EC2 instance metadata service endpoint is enabled."
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_http_endpoint)
    error_message = "metadata_http_endpoint must be either \"enabled\" or \"disabled\"."
  }
}

variable "metadata_http_tokens" {
  description = "Whether IMDSv2 session tokens are required. Use required to prevent IMDSv1 access."
  type        = string
  default     = "required"

  validation {
    condition     = contains(["optional", "required"], var.metadata_http_tokens)
    error_message = "metadata_http_tokens must be either \"optional\" or \"required\"."
  }
}

variable "create_security_group" {
  description = "Create and attach a security group instead of using existing security groups."
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "IDs of existing security groups to attach when create_security_group is false."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.security_group_ids) == length(distinct(var.security_group_ids))
    error_message = "security_group_ids must not contain duplicate IDs."
  }
}

variable "security_group_id" {
  description = "Deprecated compatibility input for one existing security group. Prefer security_group_ids."
  type        = string
  default     = null
  nullable    = true
}

variable "security_group_description" {
  description = "Description for the security group created by this module."
  type        = string
  default     = "Security group for an EC2 instance managed by Terraform."
}

variable "security_group_ingress_rules" {
  description = "Ingress rules for a newly created security group. No ingress is opened by default."
  type = list(object({
    description      = optional(string)
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    prefix_list_ids  = optional(list(string), [])
    security_groups  = optional(list(string), [])
  }))
  default = []
}

variable "security_group_egress_rules" {
  description = "Egress rules for a newly created security group. Defaults to unrestricted IPv4 egress."
  type = list(object({
    description      = optional(string)
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    prefix_list_ids  = optional(list(string), [])
    security_groups  = optional(list(string), [])
  }))
  default = []
}

variable "create_key_pair" {
  description = "Create an EC2 key pair from the supplied public key instead of using an existing key."
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Name of an existing EC2 key pair to use."
  type        = string
  default     = null
  nullable    = true
}

variable "public_key" {
  description = "OpenSSH-formatted public key used only when create_key_pair is true. The corresponding private key remains with the caller."
  type        = string
  default     = null
  nullable    = true
}

variable "root_volume_type" {
  description = "EBS volume type for the root disk."
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 1
    error_message = "root_volume_size must be at least 1 GiB."
  }
}

variable "root_volume_iops" {
  description = "Optional root volume IOPS. Set only for volume types that support configurable IOPS."
  type        = number
  default     = null
  nullable    = true
}

variable "root_volume_throughput" {
  description = "Optional root volume throughput in MiB/s (gp3 only)."
  type        = number
  default     = null
  nullable    = true
}

variable "root_volume_encrypted" {
  description = "Encrypt the root EBS volume."
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "Optional KMS key ID or ARN for root volume encryption."
  type        = string
  default     = null
  nullable    = true
}

variable "root_volume_delete_on_termination" {
  description = "Delete the root EBS volume when the instance is terminated."
  type        = bool
  default     = true
}

variable "ebs_volumes" {
  description = "Additional EBS volumes to create or attach. Set volume_id to attach an existing volume; otherwise a new volume is created."
  type = map(object({
    device_name                    = string
    volume_id                      = optional(string)
    size                           = optional(number, 20)
    type                           = optional(string, "gp3")
    iops                           = optional(number)
    throughput                     = optional(number)
    snapshot_id                    = optional(string)
    encrypted                      = optional(bool, true)
    kms_key_id                     = optional(string)
    tags                           = optional(map(string), {})
    force_detach                   = optional(bool, false)
    stop_instance_before_detaching = optional(bool, false)
    mount_path                     = optional(string)
    filesystem                     = optional(string, "ext4")
    format_on_mount                = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for volume in values(var.ebs_volumes) :
      volume.mount_path == null || (
        volume.mount_path != "/" && can(regex("^/[A-Za-z0-9._/-]+$", volume.mount_path))
      )
    ])
    error_message = "EBS mount_path values must be non-root absolute Linux paths containing only letters, numbers, dots, underscores, hyphens, and slashes."
  }

  validation {
    condition = alltrue([
      for volume in values(var.ebs_volumes) :
      volume.mount_path == null || contains(["ext4", "xfs"], volume.filesystem)
    ])
    error_message = "Mounted EBS volumes must use either ext4 or xfs."
  }

  validation {
    condition = alltrue([
      for volume in values(var.ebs_volumes) :
      can(regex("^/dev/[A-Za-z0-9]+$", volume.device_name))
    ])
    error_message = "Each EBS volume device_name must be a Linux device path such as /dev/sdf."
  }

  validation {
    condition = alltrue([
      for volume in values(var.ebs_volumes) :
      volume.volume_id != null || volume.size >= 1
    ])
    error_message = "New EBS volumes must have a size of at least 1 GiB."
  }

  validation {
    condition = alltrue([
      for volume in values(var.ebs_volumes) :
      volume.volume_id == null || can(regex("^vol-[0-9a-fA-F]+$", volume.volume_id))
    ])
    error_message = "Existing EBS volume IDs must use the AWS vol-<hex> format."
  }
}

variable "enable_cloudwatch_logging" {
  description = "Install and configure the CloudWatch agent to ship configured Linux log files."
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention_days" {
  description = "Retention period for the created CloudWatch log group."
  type        = number
  default     = 30
}

variable "cloudwatch_log_kms_key_id" {
  description = "Optional KMS key ID or ARN for CloudWatch log group encryption."
  type        = string
  default     = null
  nullable    = true
}

variable "cloudwatch_log_files" {
  description = "Linux log file paths collected when CloudWatch logging is enabled."
  type        = list(string)
  default     = ["/var/log/messages", "/var/log/cloud-init-output.log"]
}

variable "cloudwatch_metrics_collection_interval" {
  description = "CloudWatch agent collection interval in seconds for memory and disk metrics."
  type        = number
  default     = 60

  validation {
    condition     = var.cloudwatch_metrics_collection_interval >= 1 && var.cloudwatch_metrics_collection_interval <= 60
    error_message = "cloudwatch_metrics_collection_interval must be between 1 and 60 seconds."
  }
}

variable "disk_paths" {
  description = "Linux mount paths collected by the CloudWatch agent for disk utilization."
  type        = list(string)
  default     = ["/"]
}

variable "alarms" {
  description = "Optional CloudWatch alarms for CPU, memory, disk utilization, network traffic, and attached-volume I/O."
  type = object({
    enabled               = optional(bool, false)
    cpu_enabled           = optional(bool, true)
    memory_enabled        = optional(bool, true)
    disk_space_enabled    = optional(bool, true)
    network_in_enabled    = optional(bool, true)
    network_out_enabled   = optional(bool, true)
    ebs_io_enabled        = optional(bool, true)
    cpu_threshold         = optional(number, 80)
    memory_threshold      = optional(number, 80)
    disk_space_threshold  = optional(number, 80)
    network_in_threshold  = optional(number, 1000000000)
    network_out_threshold = optional(number, 1000000000)
    ebs_io_threshold      = optional(number, 10000)
    period                = optional(number, 300)
    evaluation_periods    = optional(number, 2)
    treat_missing_data    = optional(string, "missing")
  })
  default = {}

  validation {
    condition = (
      var.alarms.cpu_threshold > 0 && var.alarms.cpu_threshold <= 100 &&
      var.alarms.memory_threshold > 0 && var.alarms.memory_threshold <= 100 &&
      var.alarms.disk_space_threshold > 0 && var.alarms.disk_space_threshold <= 100 &&
      var.alarms.network_in_threshold >= 0 &&
      var.alarms.network_out_threshold >= 0 &&
      var.alarms.ebs_io_threshold >= 0
    )
    error_message = "CPU, memory, and disk thresholds must be greater than 0 and at most 100; network and EBS I/O thresholds cannot be negative."
  }

  validation {
    condition = (
      var.alarms.period >= 60 &&
      var.alarms.period % 60 == 0 &&
      var.alarms.evaluation_periods >= 1 &&
      contains(["missing", "ignore", "breaching", "notBreaching"], var.alarms.treat_missing_data)
    )
    error_message = "Alarm periods must be at least 60 seconds, evaluation_periods must be positive, and treat_missing_data must be a valid CloudWatch option."
  }
}

variable "additional_alarms" {
  description = "Optional caller-defined CloudWatch metric alarms. The map key is used as the alarm-name suffix unless alarm_name is specified."
  type = map(object({
    alarm_name          = optional(string)
    alarm_description   = optional(string, "Caller-configured CloudWatch alarm.")
    comparison_operator = string
    evaluation_periods  = number
    datapoints_to_alarm = optional(number)
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = optional(string, "Average")
    threshold           = number
    unit                = optional(string)
    dimensions          = optional(map(string), {})
    treat_missing_data  = optional(string, "missing")
    actions_enabled     = optional(bool, true)
    alarm_actions       = optional(list(string))
    ok_actions          = optional(list(string))
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for alarm in values(var.additional_alarms) :
      contains(
        [
          "GreaterThanOrEqualToThreshold",
          "GreaterThanThreshold",
          "LessThanThreshold",
          "LessThanOrEqualToThreshold",
        ],
        alarm.comparison_operator,
      ) &&
      alarm.evaluation_periods >= 1 &&
      alarm.period >= 60 &&
      alarm.period % 60 == 0 &&
      (
        alarm.datapoints_to_alarm == null ||
        (alarm.datapoints_to_alarm >= 1 && alarm.datapoints_to_alarm <= alarm.evaluation_periods)
      ) &&
      contains(["missing", "ignore", "breaching", "notBreaching"], alarm.treat_missing_data)
    ])
    error_message = "Additional alarms require a supported threshold comparison, positive evaluation periods, periods of at least 60 seconds in multiples of 60, valid datapoints_to_alarm, and a valid treat_missing_data value."
  }
}

variable "alarm_actions" {
  description = "Optional SNS topic ARNs or other CloudWatch alarm action ARNs."
  type        = list(string)
  default     = []
}

variable "alarm_email_addresses" {
  description = "Optional email addresses to subscribe to an SNS topic invoked by every alarm created by this module. Each recipient must confirm the subscription."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for address in var.alarm_email_addresses :
      can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", address))
    ])
    error_message = "Each alarm_email_addresses entry must be a valid email address."
  }
}

variable "alarm_ok_actions" {
  description = "Optional CloudWatch alarm action ARNs to invoke when alarms return to OK."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the instance and supporting resources."
  type        = map(string)
  default     = {}
}

variable "timeout_create" {
  description = "Timeout for creating the EC2 instance."
  type        = string
  default     = "10m"
}

variable "timeout_update" {
  description = "Timeout for updating the EC2 instance."
  type        = string
  default     = "15m"
}

variable "timeout_delete" {
  description = "Timeout for deleting the EC2 instance."
  type        = string
  default     = "10m"
}
