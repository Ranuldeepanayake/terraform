locals {
  ami               = "ami-003c463c8207b4dfa"
  instance_type     = "t2.micro"
  availability_zone = "ap-southeast-1a"
  subnet_id         = "subnet-08675481f2991773d"
  key_name          = "ec2-key-1-windows"

  tags_general = {
    resource-type = "ec2"
  }

  tags_all = merge(var.tags, local.tags_general)

  timemout_create = "10m"
  timemout_update = "15m"
  timemout_delete = "10m"
}