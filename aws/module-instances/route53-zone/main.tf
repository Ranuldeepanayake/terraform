# Centralize the caller's region, hosted-zone metadata, tags, and JSON record input.
locals {
  aws_region = "ap-southeast-1"

  tags = {
    Environment      = "dev"
    ResourceCategory = "route53"
    ManagedBy        = "terraform"
  }
}

module "ranul_click" {
  source = "../../modules/route53-zone"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  zone_name                   = "ranul.click"
  comment                     = "Delegated by namecheap"
  private_zone                = false
  vpc_associations            = []
  force_destroy               = false
  delegation_set_id           = null
  enable_query_logging        = true
  query_log_group_name        = null
  query_log_retention_in_days = 7
  records                     = jsondecode(file("${path.module}/records/ranul.click.json"))
  tags                        = local.tags
}
