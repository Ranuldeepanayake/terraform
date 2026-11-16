# EDGE endpoints require the ACM certificate in us-east-1. This module provisions the certificate in
# the provider's configured region, so EDGE is only safe when the provider region is us-east-1.
resource "aws_api_gateway_domain_name" "this" {
  count = var.custom_domain != null ? 1 : 0

  domain_name     = var.custom_domain
  security_policy = var.security_policy

  regional_certificate_arn = var.endpoint_type_custom_domain == "REGIONAL" ? aws_acm_certificate_validation.this[0].certificate_arn : null
  certificate_arn          = var.endpoint_type_custom_domain == "EDGE" ? aws_acm_certificate_validation.this[0].certificate_arn : null

  endpoint_configuration {
    types = [var.endpoint_type_custom_domain]
  }

  depends_on = [aws_acm_certificate_validation.this]
}

resource "aws_api_gateway_base_path_mapping" "this" {
  for_each = local.custom_domain_mappings_by_stage

  api_id      = aws_api_gateway_rest_api.this.id
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
  stage_name  = aws_api_gateway_stage.this[each.value.stage_name].stage_name
  base_path   = each.value.mapping_key == "" ? null : each.value.mapping_key

  depends_on = [aws_api_gateway_domain_name.this]
}

resource "aws_acm_certificate" "this" {
  count = var.custom_domain != null ? 1 : 0

  domain_name               = var.custom_domain
  validation_method         = var.certificate_validation_method
  subject_alternative_names = var.certificate_subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records are skipped when route53_hosted_zone_name is not set (e.g., EMAIL validation).
data "aws_route53_zone" "this" {
  count = (var.custom_domain != null && var.route53_hosted_zone_name != null) ? 1 : 0

  name         = var.route53_hosted_zone_name
  private_zone = var.route53_private_zone
}

resource "aws_route53_record" "certificate_validation" {
  for_each = (var.custom_domain != null && var.route53_hosted_zone_name != null) ? {
    for dvo in aws_acm_certificate.this[0].domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = data.aws_route53_zone.this[0].zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true

  depends_on = [aws_acm_certificate.this]
}

resource "aws_route53_record" "custom_domain" {
  count = (var.custom_domain != null && var.route53_hosted_zone_name != null) ? 1 : 0

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.custom_domain
  type    = "A"

  alias {
    name = var.endpoint_type_custom_domain == "REGIONAL" ? (
      aws_api_gateway_domain_name.this[0].regional_domain_name
    ) : aws_api_gateway_domain_name.this[0].cloudfront_domain_name
    zone_id = var.endpoint_type_custom_domain == "REGIONAL" ? (
      aws_api_gateway_domain_name.this[0].regional_zone_id
    ) : aws_api_gateway_domain_name.this[0].cloudfront_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_api_gateway_domain_name.this]
}

resource "aws_acm_certificate_validation" "this" {
  count = var.custom_domain != null ? 1 : 0

  certificate_arn = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [
    for record in aws_route53_record.certificate_validation : record.fqdn
  ]

  depends_on = [aws_route53_record.certificate_validation]
}
