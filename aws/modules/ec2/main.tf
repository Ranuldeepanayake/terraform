resource "aws_instance" "ec2" {
  ami               = local.ami
  instance_type     = local.instance_type
  availability_zone = local.availability_zone
  subnet_id         = var.subnet_id

  key_name          = local.key_name
  get_password_data = "false"

  vpc_security_group_ids = [var.security_group_id]
  tags                   = local.tags_all

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 10
    delete_on_termination = true
    encrypted             = false
  }

  timeouts {
    create = local.timemout_create
    update = local.timemout_update
    delete = local.timemout_delete
  }
}