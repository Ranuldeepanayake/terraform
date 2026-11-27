# Create or manage a public or VPC-associated private hosted zone.
resource "aws_route53_zone" "this" {
  name              = var.zone_name
  comment           = var.comment
  force_destroy     = var.force_destroy
  delegation_set_id = var.delegation_set_id
  tags              = var.tags

  dynamic "vpc" {
    for_each = var.private_zone ? var.vpc_associations : []
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  lifecycle {
    precondition {
      condition     = var.private_zone || length(var.vpc_associations) == 0
      error_message = "vpc_associations can only be set for a private hosted zone."
    }
  }
}
