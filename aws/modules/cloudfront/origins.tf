# Create OACs only for enabled S3 origins that don't use an existing OAC.
resource "aws_cloudfront_origin_access_control" "this" {
  for_each = {
    for key, origin in local.s3_origins : key => origin
    if try(origin.create_oac, true)
  }

  name                              = coalesce(try(each.value.oac_name, null), "${var.name}-${each.key}-oac")
  description                       = coalesce(try(each.value.oac_description, null), "CloudFront OAC for ${each.key}")
  origin_access_control_origin_type = "s3"
  signing_behavior                  = try(each.value.oac_signing_behavior, "always")
  signing_protocol                  = "sigv4"
}
