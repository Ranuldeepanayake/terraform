# Configuration Locals - Modify these to customize the ElastiCache Valkey cluster

locals {
  aws_region  = "ap-southeast-1"
  environment  = "dev"
  project_name = "caching"
  cache_name   = "primary"
  cluster_id   = "${local.project_name}-${local.cache_name}"

  tags = {
    Environment      = local.environment
    ProjectName      = local.project_name
    ResourceCategory = "cache"
    ManagedBy        = "terraform"
  }
}

resource "random_password" "valkey_auth" {
  length  = 16
  special = true
}

module "elasticache_valkey" {
  source = "../../modules/elasticache-valkey"

  deployment_mode = "provisioned"
  cluster_id      = local.cluster_id
  engine_version  = "8.0"
  node_type       = "cache.t4g.micro"
  num_cache_nodes = 1

  multi_az_enabled           = false
  automatic_failover_enabled = false

  parameter_group_family = "valkey8.0"
  parameter_group_name   = null
  parameters = {
    # "maxmemory-policy" = "allkeys-lru"
    # "timeout"          = "300"
  }

  subnet_ids = [
    "subnet-089b9610c4dee02f4",
    "subnet-0776c6b9deb42264e"
  ]

  vpc_id            = "vpc-02ae59b36d4cf20d7"
  subnet_group_name = "${local.project_name}-${local.cache_name}"
  port              = 6379

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

  auth_token_enabled = true
  auth_token         = random_password.valkey_auth.result
  auth_secret_name   = null

  at_rest_encryption_enabled    = true
  at_rest_encryption_kms_key_id = null
  transit_encryption_enabled    = false
  transit_encryption_mode       = "preferred"

  cloudwatch_log_enabled = true
  create_log_groups      = true
  log_retention_days     = 7
  slow_log_group_name    = null
  engine_log_group_name  = null

  snapshot_retention_limit = 0
  snapshot_window          = "03:00-05:00"

  maintenance_window         = "sun:03:00-sun:04:00"
  auto_minor_version_upgrade = true
  apply_immediately          = false

  create_sns_topic       = true
  notification_topic_arn = null
  alert_email_addresses  = ["ranuldeepanayake@outlook.com"]

  create_alarms              = true
  alarm_cpu_threshold        = 75
  alarm_eviction_threshold   = 1000
  alarm_connection_threshold = 1000
  alarm_memory_threshold     = 80

  custom_alarms = {
    # Example: Add a custom alarm for high network bytes in
    # high_network_in = {
    #   metric_name         = "NetworkBytesIn"
    #   comparison_operator = "GreaterThanThreshold"
    #   threshold           = 1000000000  # 1 GB
    #   alarm_description   = "Alert when network bytes in exceeds 1 GB"
    # }
  }

  tags = local.tags
}
