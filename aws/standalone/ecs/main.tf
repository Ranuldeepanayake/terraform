# -------------------------------
# ECS Cluster
# -------------------------------
resource "aws_ecs_cluster" "ec2_cluster" {
  name = var.cluster_name
}

# --------------------------------------------------
# ECS EC2 Instance IAM Role, attachment and profile
# --------------------------------------------------
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.cluster_name}-ecsInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_role_attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_profile" {
  name = "${var.cluster_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# -------------------------------
# Security Group for ECS EC2
# -------------------------------
resource "aws_security_group" "ecs_sg" {
  name        = "${var.cluster_name}-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere (IPv4)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow HTTP from anywhere (IPv6)"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

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
    description = "Allow NFS (IPv4)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.5/32"]
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

# -------------------------------
# ECS backing EC2 Instance
# -------------------------------
resource "aws_instance" "ecs_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  #count                       = var.ec2_count
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.ecs_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ecs_profile.name
  associate_public_ip_address = var.enable_ipv4
  ipv6_address_count          = 1
  key_name                    = var.key_name

  user_data = <<-EOF
#!/bin/bash
#Create the ECS config file. 
echo ECS_CLUSTER=${aws_ecs_cluster.ec2_cluster.name} >> /etc/ecs/ecs.config

#Add the EFS DNS entry (since the EFS mount target and EC2 instances are in different subnets).
echo "10.0.2.5 fs-07aa1cfce7bb8f621.efs.ap-southeast-1.amazonaws.com" >> /etc/hosts

#Mount the EFS mount.
yum install -y amazon-efs-utils
mkdir -p /mnt/efs/mysql-data
sudo mount -t efs -o tls fs-07aa1cfce7bb8f621.efs.ap-southeast-1.amazonaws.com:/mysql-data /mnt/efs/mysql-data
#mount -t efs -o tls ${var.efs_id}:/mysql-data /mnt/efs/mysql-data
EOF

  tags = {
    Name = "${var.cluster_name}-host-1"
    #Name = "${var.cluster_name}-host-${count.index + 1}"
  }

}

# -------------------------------
# ECS Task Definition
# -------------------------------
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-ec2"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = var.task_image
      cpu       = 64 #Optional soft limit. 1024 = 1 CPU
      memory    = 64 #Optional hard limit. 1 = 1 MB
      essential = true,
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp"
        }
      ]
    },
    {
      name      = "mysql"
      image     = "mysql:latest"
      cpu       = 128 #Optional soft limit. 1024 = 1 CPU
      memory    = 512 #Optional hard limit. 1 = 1 MB
      essential = true,
      portMappings = [
        {
          containerPort = 3306,
          hostPort      = 3306,
          protocol      = "tcp"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "mysql-data"
          containerPath = "/var/lib/mysql"
          readOnly      = false
        }
      ]
      environment = [
        {
          name  = "MYSQL_ROOT_PASSWORD"
          value = "1qaz2wsx"
        },
        {
          name  = "MYSQL_USER"
          value = "ranul"
        },
        {
          name  = "MYSQL_PASSWORD"
          value = "1qaz2wsx"
        },
        {
          name  = "MYSQL_DATABASE"
          value = "test"
        }
      ]
    }
  ])

  volume {
    name = "mysql-data"

    host_path = "/mnt/efs/mysql-data"
  }
}

# -------------------------------
# ECS Service
# -------------------------------
resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-ec2-service"
  cluster         = aws_ecs_cluster.ec2_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = var.service_count
  launch_type     = "EC2"

  #Required only for bridge or awsvpc mode
  #network_configuration {
  #  subnets         = [var.subnet_id]
  #  security_groups = [aws_security_group.ecs_sg.id]
  #}

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}
