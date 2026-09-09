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

variable "node_group_name" {
  type        = string
  description = "Name of the managed node group"
  default     = "eks-node-group"
}

variable "desired_node_count" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 3
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 3
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 4
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types for worker nodes"
  default     = ["t3.small"]
}

variable "node_disk_size" {
  type        = number
  description = "Disk size in GiB for worker nodes"
  default     = 20
}

variable "cluster_admin_user_arn" {
  type        = string
  description = "ARN of the IAM user to grant cluster admin access"
}

variable "enable_cluster_autoscaling" {
  type        = bool
  description = "Enable cluster autoscaling for managed node group"
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

variable "ec2_ssh_key_name" {
  type        = string
  description = "EC2 key pair name for SSH access to worker nodes (optional; if not provided, use AWS Systems Manager Session Manager)"
  default     = null
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

variable "letsencrypt_email_address" {
  description = "Email address registered with Let's Encrypt for ACME account notifications."
  type        = string

  validation {
    condition = can(regex(
      "^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
      var.letsencrypt_email_address
    ))

    error_message = "letsencrypt_email must be a valid email address."
  }
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
