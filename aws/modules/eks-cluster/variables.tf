variable "aws_region" {
  type        = string
  description = "AWS region for EKS cluster"
  default     = "ap-southeast-1"
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC ID where EKS cluster will be deployed"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "eks-cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version to use for the EKS cluster"
  default     = "1.36"
}

variable "cluster_upgrade_support_type" {
  type        = string
  description = "EKS Kubernetes version support policy. EXTENDED enters extended support after standard support ends; STANDARD opts out of extended support and allows automatic upgrade at end of standard support."
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.cluster_upgrade_support_type)
    error_message = "cluster_upgrade_support_type must be either 'STANDARD' or 'EXTENDED'."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets (for worker nodes)"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets (for NAT gateways and load balancers)"
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for subnets"
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "node_groups" {
  description = "Managed node groups keyed by stable Terraform identifiers. All groups share this module's node IAM role and baseline security policy."
  type = map(object({
    node_group_name = string
    min_size        = number
    desired_size    = number
    max_size        = number

    instance_types       = optional(list(string), ["t3.small"])
    capacity_type        = optional(string, "ON_DEMAND")
    disk_size            = optional(number)
    kubernetes_version   = optional(string)
    release_version      = optional(string)
    ami_type             = optional(string)
    force_update_version = optional(bool, false)

    subnet_ids = optional(list(string))
    labels     = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])

    launch_template = optional(object({
      id                        = optional(string)
      name                      = optional(string)
      version                   = optional(string)
      custom_ami                = optional(bool, false)
      instance_type_in_template = optional(bool, false)
    }))
    remote_access = optional(object({
      ec2_ssh_key               = optional(string)
      source_security_group_ids = optional(set(string), [])
    }))
    update_config = optional(object({
      max_unavailable            = optional(number)
      max_unavailable_percentage = optional(number)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = (
      length(var.node_groups) > 0 &&
      length(distinct([for group in values(var.node_groups) : group.node_group_name])) == length(var.node_groups) &&
      alltrue([
        for group in values(var.node_groups) :
        length(group.node_group_name) <= 63 &&
        can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", group.node_group_name)) &&
        group.min_size >= 0 &&
        group.desired_size >= group.min_size &&
        group.max_size >= group.desired_size &&
        group.max_size >= 1 &&
        contains(["ON_DEMAND", "SPOT"], group.capacity_type) &&
        (group.disk_size == null || group.disk_size >= 1) &&
        (group.subnet_ids == null || length(group.subnet_ids) > 0) &&
        (
          length(group.instance_types) > 0 ||
          (group.launch_template != null && group.launch_template.instance_type_in_template)
        ) &&
        (
          group.launch_template == null ||
          (
            (group.launch_template.id != null) != (group.launch_template.name != null) &&
            (!group.launch_template.instance_type_in_template || length(group.instance_types) == 0) &&
            group.remote_access == null &&
            (!group.launch_template.custom_ami || (
              group.kubernetes_version == null &&
              group.release_version == null &&
              group.ami_type == null
            ))
          )
        ) &&
        (
          group.update_config == null ||
          (
            (group.update_config.max_unavailable != null) !=
            (group.update_config.max_unavailable_percentage != null) &&
            (group.update_config.max_unavailable == null || group.update_config.max_unavailable >= 1) &&
            (
              group.update_config.max_unavailable_percentage == null ||
              (
                group.update_config.max_unavailable_percentage >= 1 &&
                group.update_config.max_unavailable_percentage <= 100
              )
            )
          )
        ) &&
        alltrue([
          for taint in group.taints :
          contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], taint.effect)
        ])
      ])
    )
    error_message = "Each node group must have a unique valid EKS name, min <= desired <= max, a supported capacity type, valid subnet/disk settings, and compatible launch-template, update, and taint settings."
  }
}

variable "eks_access_entries" {
  description = "IAM users or roles with EKS access."

  type = map(object({
    principal_arn = string
    policy_arn    = string

    access_scope = object({
      type       = string
      namespaces = optional(set(string), [])
    })
  }))

  default = {}

  validation {
    condition = alltrue([
      for entry in values(var.eks_access_entries) :
      contains(["cluster", "namespace"], entry.access_scope.type) &&
      (entry.access_scope.type == "cluster" || length(entry.access_scope.namespaces) > 0)
    ])

    error_message = "Access scope type must be 'cluster' or 'namespace'; namespace scope requires at least one namespace."
  }
}

variable "enable_cluster_autoscaling" {
  type        = bool
  description = "Add Cluster Autoscaler discovery tags to the Auto Scaling groups for all managed node groups. Does not install Cluster Autoscaler."
  default     = true
}

variable "cloudwatch_log_retention_days" {
  type        = number
  description = "Number of days to retain CloudWatch logs for EKS control plane"
  default     = 7
}

variable "enable_cluster_logging" {
  type        = list(string)
  description = "List of control plane logging types to enable (api, audit, authenticator, controllerManager, scheduler)"
  default     = ["api", "audit", "authenticator"]
}

variable "endpoint_private_access" {
  type        = bool
  description = "Enable private API server endpoint (allows cluster access from within VPC)"
  default     = true
}

variable "endpoint_public_access" {
  type        = bool
  description = "Enable public API server endpoint (allows cluster access from the internet)"
  default     = true
}

variable "authentication_mode" {
  type        = string
  description = "Authentication mode for the cluster - API (recommended) or API_AND_CONFIG_MAP (for backward compatibility with aws-auth ConfigMap)"
  default     = "API"

  validation {
    condition     = contains(["API", "API_AND_CONFIG_MAP"], var.authentication_mode)
    error_message = "authentication_mode must be either 'API' or 'API_AND_CONFIG_MAP'"
  }
}

variable "bootstrap_cluster_creator_admin_permissions" {
  type        = bool
  description = "Grant cluster admin permissions to the IAM entity that creates the cluster"
  default     = true
}

variable "external_dns_policy_name" {
  type        = string
  description = "Name of the pre-created IAM policy that grants ExternalDNS Route53 permissions"
  default     = "CustomPolicyEKSExternalDNS"
}

variable "external_dns_policy_arn" {
  type        = string
  description = "Optional full ARN of the pre-created ExternalDNS IAM policy. If null, the ARN is built from external_dns_policy_name in the current account."
  default     = null
}

variable "service_ipv4_cidr" {
  type        = string
  description = "CIDR block for Kubernetes service IP addresses. Must not overlap with VPC or pod CIDR."
  default     = "172.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_ipv4_cidr, 0))
    error_message = "service_ipv4_cidr must be a valid CIDR block"
  }
}

variable "cert_manager_namespace" {
  description = "Kubernetes namespace where cert-manager is installed."
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_service_account" {
  description = "Kubernetes ServiceAccount used by the cert-manager controller."
  type        = string
  default     = "cert-manager"
}

variable "route53_zones" {
  description = "Route 53 hosted zones that cert-manager can use for DNS-01 validation."

  type = map(object({
    zone_id  = string
    dns_zone = string
  }))
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default = {
    ManagedBy = "terraform"
  }
}

variable "kubeconfig_path" {
  type        = string
  description = "Optional absolute or workspace-relative path for a generated kubeconfig file. Set to null to skip local file creation."
  default     = null
}

variable "private_route_cidr" {
  type        = string
  description = "Destination CIDR for private subnet default routes through NAT gateways."
  default     = "0.0.0.0/0"
}

variable "public_route_cidr" {
  type        = string
  description = "Destination CIDR for the public subnet default route through the internet gateway."
  default     = "0.0.0.0/0"
}

variable "cluster_egress_cidr_blocks" {
  type        = list(string)
  description = "IPv4 CIDR blocks allowed for EKS control-plane security-group egress."
  default     = ["0.0.0.0/0"]
}

variable "node_egress_cidr_blocks" {
  type        = list(string)
  description = "IPv4 CIDR blocks allowed for worker-node security-group egress."
  default     = ["0.0.0.0/0"]
}

variable "load_balancer_ingress_cidr_blocks" {
  type        = list(string)
  description = "IPv4 CIDR blocks allowed to reach worker-node HTTP and HTTPS ports for load-balanced workloads."
  default     = ["0.0.0.0/0"]
}

variable "addon_conflict_resolution" {
  type        = string
  description = "Conflict behavior used when creating or updating managed EKS add-ons."
  default     = "OVERWRITE"

  validation {
    condition     = contains(["NONE", "OVERWRITE", "PRESERVE"], var.addon_conflict_resolution)
    error_message = "addon_conflict_resolution must be NONE, OVERWRITE, or PRESERVE."
  }
}

# Alarm settings are optional so existing callers retain their current resource
# behavior until they explicitly enable cluster monitoring.
variable "alarms" {
  description = "Optional built-in CloudWatch alarms for node and EKS control-plane health. Container Insights is installed when enabled."
  type = object({
    enabled                              = optional(bool, false)
    period                               = optional(number, 300)
    evaluation_periods                   = optional(number, 2)
    treat_missing_data                   = optional(string, "missing")
    cpu_threshold                        = optional(number, 80)
    memory_threshold                     = optional(number, 80)
    disk_space_threshold                 = optional(number, 80)
    disk_iops_threshold                  = optional(number, 10000)
    disk_throughput_threshold            = optional(number, 100000000)
    disk_latency_queue_threshold         = optional(number, 10)
    network_throughput_threshold         = optional(number, 100000000)
    network_dropped_packets_threshold    = optional(number, 100)
    failed_node_count_threshold          = optional(number, 0)
    unschedulable_pods_threshold         = optional(number, 1)
    api_server_5xx_threshold             = optional(number, 1)
    api_server_429_threshold             = optional(number, 10)
    api_server_latency_seconds_threshold = optional(number, 1)
    etcd_size_bytes_threshold            = optional(number, 8000000000)
  })
  default = {}

  validation {
    condition = (
      var.alarms.period >= 60 && var.alarms.period % 60 == 0 &&
      var.alarms.evaluation_periods >= 1 &&
      contains(["missing", "ignore", "breaching", "notBreaching"], var.alarms.treat_missing_data) &&
      var.alarms.cpu_threshold > 0 && var.alarms.cpu_threshold <= 100 &&
      var.alarms.memory_threshold > 0 && var.alarms.memory_threshold <= 100 &&
      var.alarms.disk_space_threshold > 0 && var.alarms.disk_space_threshold <= 100 &&
      var.alarms.disk_iops_threshold >= 0 && var.alarms.disk_throughput_threshold >= 0 &&
      var.alarms.disk_latency_queue_threshold >= 0 && var.alarms.network_throughput_threshold >= 0 &&
      var.alarms.network_dropped_packets_threshold >= 0 && var.alarms.failed_node_count_threshold >= 0 &&
      var.alarms.unschedulable_pods_threshold >= 0 && var.alarms.api_server_5xx_threshold >= 0 &&
      var.alarms.api_server_429_threshold >= 0 && var.alarms.api_server_latency_seconds_threshold > 0 &&
      var.alarms.etcd_size_bytes_threshold > 0
    )
    error_message = "Alarm periods and thresholds must be valid positive values; utilization thresholds must be at most 100 and treat_missing_data must be a supported CloudWatch value."
  }
}

# Caller-defined metric alarms use the same shape as the EC2 module. They are
# only created when alarms.enabled is true.
variable "additional_alarms" {
  description = "Optional caller-defined CloudWatch metric alarms, created only when built-in alarms are enabled."
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
  }))
  default = {}

  validation {
    condition = alltrue([
      for alarm in values(var.additional_alarms) :
      contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"], alarm.comparison_operator) &&
      alarm.evaluation_periods >= 1 && alarm.period >= 60 && alarm.period % 60 == 0 &&
      contains(["missing", "ignore", "breaching", "notBreaching"], alarm.treat_missing_data)
    ])
    error_message = "Additional alarms require a supported comparison operator, positive evaluation periods, periods of at least 60 seconds in whole minutes, and valid missing-data behavior."
  }
}

variable "alarm_actions" {
  description = "Optional SNS topic or other action ARNs applied to built-in alarms."
  type        = list(string)
  default     = []
}

variable "alarm_ok_actions" {
  description = "Optional action ARNs invoked when built-in alarms return to OK."
  type        = list(string)
  default     = []
}

# Caller may name the module-created standard topic or supply an existing SNS topic.
variable "alarm_sns_topic_name" {
  description = "Optional name for the SNS email alert topic created by this module. Ignored when alarm_sns_topic_arn is supplied."
  type        = string
  default     = null

  validation {
    condition     = var.alarm_sns_topic_name == null || (trimspace(var.alarm_sns_topic_name) != "" && !endswith(var.alarm_sns_topic_name, ".fifo"))
    error_message = "alarm_sns_topic_name must be non-empty and must not end in .fifo because email alarm notifications use a standard SNS topic."
  }
}

variable "alarm_sns_topic_arn" {
  description = "Optional existing standard SNS topic ARN for alarm notifications. When set, the module reuses it instead of creating a topic."
  type        = string
  default     = null

  validation {
    condition     = var.alarm_sns_topic_arn == null || can(regex("^arn:[^:]+:sns:[^:]+:[0-9]{12}:[^:]+$", var.alarm_sns_topic_arn))
    error_message = "alarm_sns_topic_arn must be a valid standard SNS topic ARN."
  }
}

variable "alarm_email_addresses" {
  description = "Email recipients subscribed to the selected alarm SNS topic. Each recipient must confirm the SNS subscription."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for address in var.alarm_email_addresses : can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", address))])
    error_message = "Each alarm_email_addresses entry must be a valid email address."
  }
}
