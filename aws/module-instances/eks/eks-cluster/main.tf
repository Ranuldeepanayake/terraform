locals {
  aws_region   = "ap-southeast-1"
  project      = "common-infra"
  cluster_name = "eks"

  tags = {
    Environment   = "dev"
    ManagedBy     = "terraform"
    ResourceGroup = "eks"
    Project       = local.project
  }
}

module "eks_cluster" {
  source = "../../../modules/eks-cluster"

  cluster_name    = "${local.project}_${local.cluster_name}"
  cluster_version = "1.37"
  aws_region      = local.aws_region

  node_groups = {
    a = {
      node_group_name    = "${local.project}_${local.cluster_name}_eks-node-group-1"
      instance_types     = ["c7i-flex.large"]
      capacity_type      = "ON_DEMAND"
      kubernetes_version = "1.37"
      disk_size          = 20
      min_size           = 1
      desired_size       = 2
      max_size           = 3
      update_config = {
        max_unavailable = 1
      }
      remote_access = {
        ec2_ssh_key = "general-purpose-1"
      }
    }
    b = {
      node_group_name    = "${local.project}_${local.cluster_name}_eks-node-group-2"
      instance_types     = ["c7i-flex.large"]
      capacity_type      = "ON_DEMAND"
      kubernetes_version = "1.37"
      disk_size          = 20
      min_size           = 1
      desired_size       = 2
      max_size           = 3
      labels = {
        workload = "s3-app"
      }
      taints = [{
        key    = "workload"
        value  = "s3-app"
        effect = "NO_EXECUTE"
      }]
      update_config = {
        max_unavailable = 1
      }
      remote_access = {
        ec2_ssh_key = "general-purpose-1"
      }
    }
  }

  # Enable cluster autoscaling.
  enable_cluster_autoscaling = true

  # Existing VPC ID where the EKS cluster will be deployed.
  vpc_id = "vpc-02ae59b36d4cf20d7"

  # CIDR blocks for private subnets where worker nodes will be placed.
  private_subnet_cidrs = ["10.0.16.0/22", "10.0.20.0/22"]

  # CIDR blocks for public subnets used by NAT gateways and load balancers.
  public_subnet_cidrs = ["10.0.12.0/24", "10.0.14.0/24"]

  # Availability zones matching the subnet definitions.
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]

  # Kubernetes service CIDR; it must not overlap with the VPC or pod CIDR.
  service_ipv4_cidr            = "172.20.0.0/16"
  cert_manager_namespace       = "cert-manager"
  cert_manager_service_account = "cert-manager"

  # API endpoint access configuration.
  # Private access allows cluster access from within the VPC.
  # Public access allows access from the internet; restrict it for production deployments.
  endpoint_private_access = true
  endpoint_public_access  = true

  # Authentication mode: API is recommended; API_AND_CONFIG_MAP supports legacy aws-auth behavior.
  authentication_mode = "API"

  # Set false to use the explicit access entries below for administrator access.
  bootstrap_cluster_creator_admin_permissions = false

  # IAM entities to grant cluster access (required when bootstrap creator admin permissions are disabled).
  eks_access_entries = {
    admin_user = {
      principal_arn = "arn:aws:iam::104322896078:role/CustomRoleSuperAdmin"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }
    terraform_user = {
      principal_arn = "arn:aws:iam::104322896078:user/terraform"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
      access_scope = {
        type       = "namespace"
        namespaces = ["kube-system", "ingress-nginx"]
      }
    }
  }

  # Route 53 zones used for cert-manager DNS challenges.
  route53_zones = {
    ranul_click = {
      dns_zone = "ranul.click"
      zone_id  = "Z0233745IB90EWVKK2K1"
    }
  }

  # Existing ExternalDNS policy and cert-manager identity configuration.
  external_dns_policy_name = "CustomPolicyEKSExternalDNS"
  external_dns_policy_arn  = null

  # EKS Kubernetes version support policy: EXTENDED or STANDARD.
  # EXTENDED enters paid extended support after standard support ends.
  # STANDARD opts out of paid extended support and allows AWS to automatically upgrade the cluster at the end of standard support.
  cluster_upgrade_support_type = "STANDARD"

  # CloudWatch log retention days for EKS control-plane logs.
  cloudwatch_log_retention_days = 7

  # Enable built-in node/control-plane alarms and optional caller-defined alarms.
  alarms = {
    enabled = true
  }

  # Optional extra action ARNs; the module's email SNS topic is attached automatically.
  alarm_actions = []

  # Optional module-owned topic name; defaults to "<cluster-name>-alerts" when no ARN is supplied.
  alarm_sns_topic_name = null

  # Reuses an existing topic and takes precedence over alarm_sns_topic_name when both are set.
  alarm_sns_topic_arn = null

  # Add one or more recipients. Each recipient must confirm the SNS subscription email.
  alarm_email_addresses = ["ranuldeepanayake@outlook.com"]

  # Example custom EKS alarm; custom alarms are ignored while alarms.enabled is false.
  additional_alarms = {
    node_disk_pressure = {
      alarm_description   = "Alert when any node reports Kubernetes disk pressure."
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "node_status_condition_disk_pressure"
      namespace           = "ContainerInsights"
      period              = 300
      statistic           = "Maximum"
      threshold           = 0
      dimensions          = { ClusterName = "${local.project}_${local.cluster_name}" }
    }
  }

  # Enable control-plane logging.
  enable_cluster_logging = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Do not create a local kubeconfig file; set a path to enable generation.
  kubeconfig_path = null

  # Allow private-subnet resources to reach any destination through NAT gateways.
  private_route_cidr = "0.0.0.0/0"

  # Allow public-subnet resources to reach any destination through the internet gateway.
  public_route_cidr = "0.0.0.0/0"

  # Allow the EKS control-plane security group to send traffic to any IPv4 destination.
  cluster_egress_cidr_blocks = ["0.0.0.0/0"]

  # Allow worker nodes to send traffic to any IPv4 destination, normally through NAT.
  node_egress_cidr_blocks = ["0.0.0.0/0"]

  # Allow internet-wide HTTP and HTTPS access to load-balanced workloads on the nodes.
  load_balancer_ingress_cidr_blocks = ["0.0.0.0/0"]

  # Overwrite conflicting managed EKS add-on settings during create or update.
  addon_conflict_resolution = "OVERWRITE"

  # Common tags to apply to all resources.
  tags = local.tags
}
