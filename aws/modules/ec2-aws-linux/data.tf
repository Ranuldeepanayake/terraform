# Look up the subnet to derive its VPC and Availability Zone.
data "aws_subnet" "selected" {
  id = var.subnet_id
}

# Select the current Linux AMI only when the caller does not pin an AMI ID.
data "aws_ami" "linux" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Look up the caller's role when a new profile should use an existing role.
data "aws_iam_role" "existing" {
  count = !var.create_iam_role && var.create_instance_profile && var.existing_iam_role_name != null ? 1 : 0
  name  = var.existing_iam_role_name
}

# Look up an existing profile and its attached role when requested.
data "aws_iam_instance_profile" "existing" {
  count = !var.create_instance_profile && var.existing_instance_profile_name != null ? 1 : 0
  name  = var.existing_instance_profile_name
}

# Resolve the AWS partition for managed policy ARNs.
data "aws_partition" "current" {}
