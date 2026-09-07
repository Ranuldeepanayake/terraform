locals {
  tags_ec2 = {
    resource-type = "ec2"
  }

  tags_ebs = {
    resource-type = "ec2-root-volume"
  }

  timemout_create = "5m"
  timemout_update = "5m"
  timemout_delete = "5m"
}