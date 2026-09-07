# ---------------------------------------------
# Random string generation for S3 naming
# ---------------------------------------------
resource "random_string" "s3" {
  length  = 8
  upper   = false
  special = false
}

#Bucket creation.
resource "aws_s3_bucket" "bucket" {
  bucket = "bucket-${var.resource_name}-${random_string.s3.result}"

  tags = merge(local.tags_s3,
    {
      Name = "bucket-${var.resource_name}-${random_string.s3.result}"
    }
  )
}

#Bucket policy.
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


#Enable static website hosting.
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }
}

#Static webpage.
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "index.html"
  source       = "src/index.html"
  content_type = "text/html"
  #acl          = "public-read"
}