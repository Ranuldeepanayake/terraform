# Request the viewer certificate in us-east-1, which CloudFront requires for ACM certificates.
resource "aws_acm_certificate" "this" {
  count    = var.create_acm_certificate ? 1 : 0
  provider = aws.us_east_1

  domain_name       = var.aliases[0]
  validation_method = "DNS"

  subject_alternative_names = length(var.aliases) > 1 ? slice(var.aliases, 1, length(var.aliases)) : []
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Publish ACM's DNS validation CNAMEs in the supplied public hosted zone.
resource "aws_route53_record" "certificate_validation" {
  for_each = var.create_acm_certificate ? toset(var.aliases) : toset([])

  zone_id = var.route53_zone_id
  name    = one([for option in aws_acm_certificate.this[0].domain_validation_options : option if option.domain_name == each.key]).resource_record_name
  type    = one([for option in aws_acm_certificate.this[0].domain_validation_options : option if option.domain_name == each.key]).resource_record_type
  ttl     = 60
  records = [one([for option in aws_acm_certificate.this[0].domain_validation_options : option if option.domain_name == each.key]).resource_record_value]
}

# Wait for ACM to issue the certificate after its DNS validation records propagate.
resource "aws_acm_certificate_validation" "this" {
  count    = var.create_acm_certificate ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]

  timeouts {
    create = var.route53_validation_wait
  }
}

# Publish Route 53 A alias records for each configured distribution alias.
resource "aws_route53_record" "distribution_a_alias" {
  for_each = var.create_route53_records && var.route53_alias_records ? toset(var.aliases) : toset([])

  zone_id = var.route53_zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

# Publish Route 53 AAAA alias records when IPv6 is enabled on the distribution.
resource "aws_route53_record" "distribution_aaaa_alias" {
  for_each = var.create_route53_records && var.route53_alias_records && var.is_ipv6_enabled ? toset(var.aliases) : toset([])

  zone_id = var.route53_zone_id
  name    = each.key
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

# Preserve support for existing DNS setups that use a CNAME instead of Route 53 alias records.
resource "aws_route53_record" "distribution_cname" {
  for_each = var.create_route53_records && !var.route53_alias_records ? toset(var.aliases) : toset([])

  zone_id = var.route53_zone_id
  name    = each.key
  type    = "CNAME"
  ttl     = var.route53_record_ttl
  records = [aws_cloudfront_distribution.this.domain_name]
}
