locals {
  tags_alb = {
    resource-type = "alb"
  }

  timemout_create = "5m"
  timemout_update = "5m"
  timemout_delete = "5m"
}