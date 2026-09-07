locals {

  tags = {
    Name = "MySQL database"
    resource-type  = "RDS"
  }

  resource_name_prefix = "rds"
  subnet_group = "${aws_db_subnet_group._.name}"
  identifier        = "mysql"
  engine            = "mysql"
  engine_version    = "8.0.35"
  instance_class    = "db.t3.micro"
  allocated_storage = 10
  storage_encrypted = false     # not supported for db.t2.micro instance
  name              = ""        # use empty string to start without a database created
  username          = "root"   # password is generated
  password          = "hCX7mcYKHdQZxbx8"
  port                    = 3306
  publicly_accessible     = true
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-southeast-1"
  profile = "default"
}

resource "aws_db_instance" "_" {
  identifier = "${local.resource_name_prefix}-1"
  allocated_storage       = local.allocated_storage
  db_subnet_group_name    = local.subnet_group
  engine                  = local.engine
  engine_version          = local.engine_version
  instance_class          = local.instance_class
  db_name                 = local.name
  username                = local.username
  password                = local.password
  port                    = local.port
  publicly_accessible     = local.publicly_accessible
  storage_encrypted       = local.storage_encrypted
  skip_final_snapshot     = true
  vpc_security_group_ids  = ["sg-001429f4b76c8906d"]
}

resource "aws_db_subnet_group" "_" {
  name       = "subnet-group-1"
  subnet_ids = [
    "subnet-08675481f2991773d",
    "subnet-0f2207703f58bb129"
  ]
}

resource "aws_security_group_rule" "rds-rules" {
  type= "ingress"
  description = "RDS ingress"
  from_port   = 0
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "sg-001429f4b76c8906d"
}

output "instance_ips" {
  value = aws_db_instance._.endpoint
}
