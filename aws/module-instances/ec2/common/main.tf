locals {
  aws_region = "ap-southeast-1"

  tags = {
    Environment      = "dev"
    ResourceCategory = "ec2"
    ManagedBy        = "terraform"
    Project          = "common-infra"
  }
}

# Configure the EC2 instance directly through module arguments.
module "ec2" {
  source = "../../../modules/ec2-linux"

  instance_name = "common-ec2"
  ami_id        = null # Uses the latest Amazon Linux 2023 x86_64 AMI.
  instance_type = "t3.micro"
  subnet_id     = "subnet-089b9610c4dee02f4"

  associate_public_ip_address = true
  detailed_monitoring         = false
  ipv6_only                   = false # Set true only when subnet_id is an IPv6-native subnet.
  ipv6_address_count          = 1     # Request IPv6 alongside IPv4 for this dual-stack instance.

  create_security_group = true
  security_group_ids    = []
  # Restrict these CIDRs to trusted client addresses before deploying.
  security_group_ingress_rules = [
    {
      description = "SSH from any IPv4 address"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description      = "SSH from any IPv6 address"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = ["::/0"]
    }
  ]
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

  # Set create_key_pair=false and public_key=null to use key_name for an existing AWS EC2 pair,
  # Set create_key_pair=true, public_key=<public key> and key_name=null to import an SSH public key and create a new EC2 key pair
  # which will be added to the instance authorized_keys file. The private key must be available to the SSH user.
  # Set create_key_pair=false and the key_name and public_key to null to use Systems Manager without SSH.
  create_key_pair = false
  key_name        = "general-purpose-1"
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
  cloudwatch_log_files                   = ["/var/log/messages", "/var/log/cloud-init-output.log"]
  cloudwatch_metrics_collection_interval = 60
  disk_paths                             = ["/"]

  alarms = {
    enabled               = true
    cpu_enabled           = true
    memory_enabled        = true
    disk_space_enabled    = true
    network_in_enabled    = true
    network_out_enabled   = true
    ebs_io_enabled        = true
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
      dimensions = {
        InstanceId = "__EC2_INSTANCE_ID__"
      }
    }
  }

  alarm_email_addresses = [
    "ranuldeepanayake@outlook.com"
  ]
  alarm_actions    = []
  alarm_ok_actions = []

  setup_script                = file("${path.module}/scripts/install-aws-cli.sh")
  user_data_replace_on_change = true
  metadata_http_endpoint      = "enabled"
  metadata_http_tokens        = "required"
  metadata_hop_limit          = 1
  timeout_create              = "10m"
  timeout_update              = "15m"
  timeout_delete              = "10m"

  tags = local.tags
}
