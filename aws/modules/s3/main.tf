# Create the bucket container with a stable name, deletion behavior, and common tags.
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

    precondition {
      condition     = var.enable_server_access_logging != true || var.logging_configuration != null
      error_message = "Set logging_configuration when enable_server_access_logging is true."
    }
  }
}
