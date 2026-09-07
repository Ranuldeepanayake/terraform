# AWS S3 Terraform Module

This module creates an S3 bucket with configurable ACLs and an optional bucket policy.

## Example

```hcl
module "s3_bucket" {
  source = "./modules/s3"

  bucket_name = "example-app-data"
  acl         = "private"

  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowReadOnly"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["arn:aws:s3:::example-app-data/*"]
      }
    ]
  })

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```
