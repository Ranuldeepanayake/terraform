# Configure an S3 static website endpoint or redirect when website hosting is enabled.
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.enable_static_hosting ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "index_document" {
    for_each = var.website_configuration.index_document == null ? [] : [var.website_configuration.index_document]
    content {
      suffix = index_document.value
    }
  }

  dynamic "error_document" {
    for_each = var.website_configuration.error_document == null ? [] : [var.website_configuration.error_document]
    content {
      key = error_document.value
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = var.website_configuration.redirect_all_requests_to == null ? [] : [var.website_configuration.redirect_all_requests_to]
    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol  = redirect_all_requests_to.value.protocol
    }
  }
}

# Upload and track caller-provided files as website objects in the bucket.
resource "aws_s3_object" "website_files" {
  for_each = var.enable_static_hosting ? var.website_files : {}

  bucket        = aws_s3_bucket.this.id
  key           = each.key
  source        = each.value.source
  source_hash   = filemd5(each.value.source)
  content_type  = each.value.content_type
  cache_control = each.value.cache_control

  depends_on = [aws_s3_bucket_website_configuration.this]
}
