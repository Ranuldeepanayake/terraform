resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    {
      name = var.bucket_name
    },
    var.tags
  )

  lifecycle {
    precondition {
      condition     = var.enable_static_hosting == (var.website_configuration != null)
      error_message = "Set enable_static_hosting=true with website_configuration, or leave both disabled/unset."
    }

    precondition {
      condition     = length(var.website_files) == 0 || var.enable_static_hosting
      error_message = "website_files can only be uploaded when enable_static_hosting is true."
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_acl" "this" {
  count = var.object_ownership == "BucketOwnerEnforced" ? 0 : 1

  depends_on = [aws_s3_bucket_ownership_controls.this]

  bucket = aws_s3_bucket.this.id
  acl    = var.acl
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = var.block_public_access.block_public_acls
  block_public_policy     = var.block_public_access.block_public_policy
  ignore_public_acls      = var.block_public_access.ignore_public_acls
  restrict_public_buckets = var.block_public_access.restrict_public_buckets
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.bucket_policy == null ? 0 : 1
  bucket = aws_s3_bucket.this.id
  policy = local.bucket_policy_json

  lifecycle {
    precondition {
      condition = try(
        local.bucket_policy_document.Version != null &&
        local.bucket_policy_document.Statement != null,
        false
      )
      error_message = "bucket_policy must be a valid IAM policy document with Version and Statement fields; pass an HCL object or JSON string."
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.server_side_encryption.enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.server_side_encryption.algorithm
      kms_master_key_id = var.server_side_encryption.kms_master_key_id
    }

    bucket_key_enabled = var.server_side_encryption.algorithm == "AES256" ? null : var.server_side_encryption.bucket_key_enabled
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null || rule.value.expired_object_delete_marker == true ? [true] : []
        content {
          days                         = rule.value.expiration_days
          expired_object_delete_marker = rule.value.expired_object_delete_marker
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days == null ? [] : [rule.value.noncurrent_version_expiration_days]
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days == null ? [] : [rule.value.abort_incomplete_multipart_upload_days]
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_cors_configuration" "this" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

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

resource "aws_s3_bucket_logging" "this" {
  count  = var.logging_configuration == null ? 0 : 1
  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_configuration.target_bucket
  target_prefix = var.logging_configuration.target_prefix
}

resource "aws_s3_bucket_accelerate_configuration" "this" {
  count  = var.transfer_acceleration_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id
  status = "Enabled"
}

resource "aws_s3_bucket_request_payment_configuration" "this" {
  count  = var.request_payer == null ? 0 : 1
  bucket = aws_s3_bucket.this.id
  payer  = var.request_payer
}
