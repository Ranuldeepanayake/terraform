# Configuration Locals - Modify these to customize the ElastiCache Valkey cluster

locals {
  aws_region   = "ap-southeast-1"
  environment  = "dev"
  project_name = "caching"
  cache_name   = "primary"
  cluster_id   = "${local.project_name}-${local.cache_name}"

  tags = {
    Environment      = local.environment
    ProjectName      = local.project_name
    ResourceCategory = "elasticache"
    ManagedBy        = "terraform"
  }
}

resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  cluster_id                 = local.cluster_id
  engine_version             = "8.0"
  deployment_mode            = "provisioned"
  node_type                  = "cache.t4g.micro"
  num_cache_nodes            = 1
  multi_az_enabled           = false
  automatic_failover_enabled = false

  parameter_group_family = "valkey8"
  # If the parameter group name is null, a new parameter group will be created with any custom parameters provided. 
  # If a parameter group name is provided, it must already exist and will be used for the cluster. 
  parameter_group_name = "default.valkey8"
  # Custom parameters.
  parameters = {
    # "maxmemory-policy" = "allkeys-lru"
    # "timeout"          = "300"
  }

  vpc_id = "vpc-02ae59b36d4cf20d7"
  # Private subnets are preferred.
  subnet_ids = [
    "subnet-089b9610c4dee02f4"
  ]
  subnet_group_name = local.cluster_id
  port              = 6379

  # Create a route53 DNS record for the cluster.
  create_route53_record = true
  # Must provide a private zone ID.
  route53_zone_id = "Z0233745IB90EWVKK2K1"
  # Defaults to cluster_id if not provided.
  route53_record_name = null

  at_rest_encryption_enabled = true
  # Uses the default AWS managed KMS key for ElastiCache if not provided.
  at_rest_encryption_kms_key_id = null
  # Requires the client to support TLS.
  transit_encryption_enabled = false
  transit_encryption_mode    = "preferred"

  # Auth token requires transit encryption to be enabled. 
  auth_token_enabled = false
  # A randomly generated password will be used for the auth token if not provided.
  #auth_token         = random_password.valkey_auth.result
  # If a secret name is provided, the auth token will be stored in AWS Secrets Manager with that name. Else, a name will be generated based on the cluster ID.
  #auth_secret_name   = null

  # Logging configuration.
  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 7
  slow_log_group_name    = null
  engine_log_group_name  = null

  # Daily snaphots. Retention window '0' means no snapshots are retained.
  # Retention limit is how many days to keep a snapshot.
  snapshot_retention_limit = 0
  snapshot_window          = "03:00-05:00"

  # Maintenance window in UTC. Format: ddd:hh24:mi-ddd:hh24:mi
  maintenance_window = "sun:02:00-sun:04:00"
  # Auto minor version upgrade only during the maintenance window or manually.
  auto_minor_version_upgrade = true
  # Apply any changes either immediately or during the next maintenance window.
  apply_immediately = false

  # Create a security group for the cluster.
  create_security_group = true

  security_group_ingress_rules = {
    public_access_ipv4 = {
      description = "Public access IPv4"
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    public_access_ipv6 = {
      description = "Public access IPv6"
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_ipv6   = "::/0"
    }
  }

  security_group_egress_rules = {
    allow_all_ipv4 = {
      description = "Allow all outbound IPv4 traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
    allow_all_ipv6 = {
      description = "Allow all outbound IPv6 traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_ipv6   = "::/0"
    }
  }

  create_alarms          = true
  alarm_cpu_threshold    = 80
  alarm_memory_threshold = 80
  # Evictions per minute shows the rate at which cached data is being deleted because the cache is full (LRU/LFU policy). 
  # Indicates that the cache is undersized for your workload.
  alarm_eviction_threshold = 1000
  # Number of active client connections to the cache node.
  alarm_connection_threshold = 1000

  custom_alarms = {
    # Example: Add a custom alarm for high network bytes in
    # high_network_in = {
    #   metric_name         = "NetworkBytesIn"
    #   comparison_operator = "GreaterThanThreshold"
    #   threshold           = 1000000000  # 1 GB
    #   alarm_description   = "Alert when network bytes in exceeds 1 GB"
    # }
  }

  # Create a SNS topic for notifications and alarms. Setting to true can either create a new topic or use an existing one if provided. 
  # Setting to false will not create a topic nor use an existing one.
  create_sns_topic       = true
  # Use an existing topic if provided. Else, a new topic will be created.
  notification_topic_arn = null
  # Email addresses to receive notifications for the new SNS topic only. If using an existing topic, ensure the email addresses are subscribed to that topic.
  alert_email_addresses  = ["ranuldeepanayake@outlook.com"]

  tags = local.tags
}
