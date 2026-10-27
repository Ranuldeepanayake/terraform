locals {
  # Ubuntu caller settings are intentionally separate from the Amazon Linux
  # caller so each directory can be planned and applied independently.
  aws_region    = "ap-southeast-1"
  instance_name = "ubuntu-ec2"

  tags = {
    Environment      = "dev"
    ResourceCategory = "ec2"
    ManagedBy        = "terraform"
    Project          = "ubuntu-infra"
    OperatingSystem  = "ubuntu"
  }
}

# Configure an Ubuntu EC2 instance through the Ubuntu-specific module.
module "ec2" {
  source = "../../../modules/ec2-ubuntu"

  ami_id        = "ami-0e683f46a1f00df41"
  instance_name = "${local.tags["Project"]}_${local.instance_name}"
  instance_type = "t3.micro"
  subnet_id     = "subnet-089b9610c4dee02f4"

  associate_public_ip_address = true
  detailed_monitoring         = false
  ipv6_only                   = false
  ipv6_address_count          = 1

  create_security_group = true
  security_group_ids    = []
  # Restrict SSH to trusted CIDRs before deployment, or use SSM without SSH.
  security_group_ingress_rules = []
  security_group_egress_rules = [
    {
      description = "Allow all outbound IPv4 traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description      = "Allow all outbound IPv6 traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      ipv6_cidr_blocks = ["::/0"]
    }
  ]

  # Use Systems Manager by default. Configure create_key_pair/key_name when SSH is required.
  create_key_pair = false
  key_name        = null
  public_key      = null

  root_volume_type                  = "gp3"
  root_volume_size                  = 20
  root_volume_encrypted             = true
  root_volume_delete_on_termination = true
  ebs_volumes                       = {}

  create_iam_role                = true
  existing_iam_role_name         = null
  create_instance_profile        = true
  existing_instance_profile_name = null
  attach_ssm_managed_policy      = true
  attach_cloudwatch_agent_policy = true
  additional_iam_policy_arns     = []

  enable_cloudwatch_logging              = true
  cloudwatch_log_retention_days          = 3
  cloudwatch_log_files                   = ["/var/log/syslog", "/var/log/cloud-init-output.log"]
  cloudwatch_metrics_collection_interval = 60
  disk_paths                             = ["/"]

  alarms = {
    enabled               = true
    cpu_enabled           = true
    memory_enabled        = true
    disk_space_enabled    = true
    network_in_enabled    = true
    network_out_enabled   = true
    ebs_io_enabled        = false
    cpu_threshold         = 80
    memory_threshold      = 80
    disk_space_threshold  = 80
    network_in_threshold  = 100000000
    network_out_threshold = 100000000
    ebs_io_threshold      = 10000
    period                = 300
    evaluation_periods    = 2
    treat_missing_data    = "missing"
  }

  additional_alarms = {
    status_check_failed = {
      metric_name         = "StatusCheckFailed"
      namespace           = "AWS/EC2"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      period              = 300
      statistic           = "Maximum"
      threshold           = 0
      dimensions          = { InstanceId = "__EC2_INSTANCE_ID__" }
    }
  }

  alarm_email_addresses = []
  alarm_actions         = []
  alarm_ok_actions      = []

  # This file is Bash appended to the module-generated Ubuntu user data.
  setup_script                = file("${path.module}/scripts/setup.sh")
  user_data_replace_on_change = true
  metadata_http_endpoint      = "enabled"
  metadata_http_tokens        = "required"
  metadata_hop_limit          = 1
  timeout_create              = "10m"
  timeout_update              = "15m"
  timeout_delete              = "10m"

  tags = local.tags
}
