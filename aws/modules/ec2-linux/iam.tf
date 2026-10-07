# Create an EC2-trusted IAM role when requested.
resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  name = "${var.instance_name}-${local.random_suffix}"

  tags = merge(
    var.tags,
    {
      ResourceType = "iam-role"
      Name         = "${var.instance_name}-${local.random_suffix}"
    }
  )
}

# Attach the Systems Manager permissions required by the SSM agent.
resource "aws_iam_role_policy_attachment" "ssm" {
  count = local.iam_role_selected && var.attach_ssm_managed_policy ? 1 : 0

  role       = local.iam_role_name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach permissions required by the CloudWatch Agent when enabled.
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = local.iam_role_selected && local.cloudwatch_agent_enabled && var.attach_cloudwatch_agent_policy ? 1 : 0

  role       = local.iam_role_name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach caller-selected managed policies only to this module's newly created role.
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_iam_role ? toset(var.additional_iam_policy_arns) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# Create an instance profile and associate the selected role.
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile && (var.create_iam_role || var.existing_iam_role_name != null) ? 1 : 0

  name = "${var.instance_name}-${local.random_suffix}"
  role = local.iam_role_name

  tags = merge(
    var.tags,
    {
      ResourceType = "ec2-instance-profile"
      Name         = "${var.instance_name}-${local.random_suffix}"
    }
  )
}