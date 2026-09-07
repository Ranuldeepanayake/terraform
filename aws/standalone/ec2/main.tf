# ---------------------------------------------
# Random string generation for EC2 group naming
# ---------------------------------------------
resource "random_string" "ec2_group" {
  length  = 4
  upper   = false
  special = false
}

# -------------------------------
# Security Group for ECS EC2
# -------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-group-${random_string.ec2_group.result}-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from anywhere (IPv4)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow SSH from anywhere (IPv6)"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow HTTP from anywhere (IPv4)"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow SSH from anywhere (IPv6)"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow NFS (IPv4)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all IPv4 outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all IPv6 outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

# ----------------------------------------
# Random string generation for EC2 naming
# ----------------------------------------
resource "random_string" "ec2_suffix" {
  length  = 8
  upper   = false
  special = false
}

# -------------------------------
# EC2 Instance
# -------------------------------
resource "aws_instance" "ec2" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = var.enable_ipv4
  key_name                    = var.key_name
  get_password_data           = "false"

  tags = merge(local.tags_ec2,
    {
      Name = "ec2-general-purpose-${random_string.ec2_group.result}-${random_string.ec2_suffix.result}"
    }
  )

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10 # in GiB
    delete_on_termination = true
    encrypted             = false
    tags = merge(local.tags_ebs,
      {
        Name = "ec2-root-volume-${random_string.ec2_group.result}-${random_string.ec2_suffix.result}"
      }
    )
  }

  timeouts {
    create = local.timemout_create
    update = local.timemout_update
    delete = local.timemout_delete
  }

  user_data = <<-EOF
#!/bin/bash

#Add the EFS DNS entry (since the EFS mount target and EC2 instances are in different subnets).
echo "10.0.2.5 fs-07aa1cfce7bb8f621.efs.ap-southeast-1.amazonaws.com" >> /etc/hosts

#Setup docker
yum install docker -y
usermod -aG docker ec2-user
systemctl start docker
systemctl enable docker

#Run test nginx container.
docker run -d -p 3000:80 --name nginx-test nginx:latest

EOF

}