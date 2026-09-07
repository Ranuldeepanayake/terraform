# Configure a custom domain name for the API Gateway. However, it will only be effective once the proceeding resources such as the Route 53 records and ACM certificate 
# are created and validated. 
resource "aws_apigatewayv2_domain_name" "this" {
  count = var.custom_domain != null ? 1 : 0

  domain_name = var.custom_domain

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.this[0].certificate_arn
    endpoint_type   = var.endpoint_type
    security_policy = var.security_policy
  }

  depends_on = [
    aws_acm_certificate_validation.this
  ]
}

# Map the created custom domain name for the API Gateway. However, it will only be effective once the proceeding resources such as the Route 53 records and ACM certificate 
# are created and validated. 
resource "aws_apigatewayv2_api_mapping" "this" {
  count = var.custom_domain != null ? 1 : 0

  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this[0].id
  stage       = aws_apigatewayv2_stage.default.id

  depends_on = [
    aws_apigatewayv2_domain_name.this
  ]
}

# Create an ACM certificate for the custom domain name. However, it will only be effective once the proceeding resources such as the Route 53 record is created and validated.
resource "aws_acm_certificate" "this" {
  count = var.custom_domain != null ? 1 : 0

  domain_name               = var.custom_domain
  validation_method         = var.certificate_validation_method
  subject_alternative_names = var.certificate_subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }
}

# Use data from an existing route 53 zone.
data "aws_route53_zone" "this" {
  count = var.custom_domain != null ? 1 : 0

  name         = var.route53_hosted_zone_name
  private_zone = var.route53_private_zone
}

# Create a route 53 CNAME record for ACM certificate validation. This proves ownership of the domain name.
resource "aws_route53_record" "certificate_validation" {
  for_each = var.custom_domain != null ? {
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

  depends_on = [
    aws_acm_certificate.this
  ]
}

# Wait for the ACM certificate to be validated.
resource "aws_acm_certificate_validation" "this" {
  count = var.custom_domain != null ? 1 : 0

  certificate_arn = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [
    for record in aws_route53_record.certificate_validation : record.fqdn
  ]

  depends_on = [
    aws_route53_record.certificate_validation
  ]
}