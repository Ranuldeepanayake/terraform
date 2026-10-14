# S3 bucket Terraform module

Creates and configures an S3 general-purpose bucket, including access controls, encryption, lifecycle management, browser CORS, website hosting, and access logging. The module does not upload objects or create the destination bucket for server access logs.

## Features

- Configurable bucket name, tags, and non-empty-bucket deletion behavior.
- Versioning, object ownership controls, optional canned ACL, and all four S3 public-access-block settings.
- Optional bucket policy supplied as an HCL object or JSON string.
- Default SSE-S3 or SSE-KMS encryption, including optional S3 Bucket Keys.
- Multiple prefix-based lifecycle rules for expiration, noncurrent-version cleanup, storage-class transitions, and incomplete multipart uploads.
- Optional CORS rules, static website hosting, server access logging, Transfer Acceleration, and Requester Pays.
- Optional upload and lifecycle management of caller-owned static website files.
- Outputs for bucket identifiers, regional endpoints, configuration status, and optional website endpoints.

## Requirements

- Terraform 1.6 or later.
- AWS provider configured by the calling root module, with permissions to create and configure the requested S3 resources.

The module deliberately does not declare an AWS provider configuration; configure credentials and region in the caller. `aws_region` remains as a compatibility input but does not configure the provider.

## Basic usage

```hcl
module "app_bucket" {
  source = "../../modules/s3"

  bucket_name        = "example-app-data"
  versioning_enabled = true
  force_destroy      = false

  tags = {
    Environment = "production"
    Application = "app"
    ManagedBy   = "Terraform"
  }
}
```

By default, the module enables BucketOwnerEnforced object ownership, blocks public access, and enables SSE-S3 encryption. These are secure defaults; make public access changes only when required and reviewed.

## Bucket policy input formats

Pass a policy as an HCL object directly in the caller's `.tf` configuration:

```hcl
bucket_policy = {
  Version = "2012-10-17"
  Statement = [{
    Sid       = "ReadObjects"
    Effect    = "Allow"
    Principal = "*"
    Action    = ["s3:GetObject"]
    Resource  = "arn:aws:s3:::placeholder-bucket/*"
  }]
}
```

Or pass JSON as a string, for example from a JSON file in the caller:

```hcl
bucket_policy = file("${path.module}/policies/bucket-policy.json")
```

The policy may also be provided via a caller variable. Terraform does not load executable `.tf` files with `file()`; put an HCL policy object in a `.tf` file or load a JSON document. Both `placeholder-bucket` and `__BUCKET_NAME__` in policy strings are replaced with the actual bucket name, which is useful when the caller generates a unique name. Policy contents are otherwise passed through without reconstructing or dropping statement fields.

The example `Principal = "*"` makes object reads public only if the policy allows it and account-level and bucket-level public access blocks permit it. Avoid public policies unless the bucket is intentionally public.

## Common optional configurations

### SSE-KMS encryption

```hcl
server_side_encryption = {
  enabled            = true
  algorithm          = "aws:kms"
  kms_master_key_id  = "arn:aws:kms:ap-southeast-1:123456789012:key/00000000-0000-0000-0000-000000000000"
  bucket_key_enabled = true
}
```

Supported algorithms are `AES256`, `aws:kms`, and `aws:kms:dsse`. The default is `AES256`. KMS key policy and IAM permissions must allow the relevant S3 usage. Set `enabled = false` only when encryption configuration is managed elsewhere.

### Lifecycle

```hcl
lifecycle_rules = [
  {
    id                                     = "archive-and-cleanup"
    enabled                                = true
    prefix                                 = "logs/"
    expiration_days                       = 365
    noncurrent_version_expiration_days     = 90
    abort_incomplete_multipart_upload_days = 7
    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 120
        storage_class = "GLACIER"
      }
    ]
  }
]
```

Lifecycle expiration permanently removes objects or noncurrent versions according to the rule. Review retention requirements and test prefixes before enabling expiration. Noncurrent-version actions are useful only when versioning is enabled. S3 applies lifecycle actions asynchronously, not at an exact time.

### CORS

```hcl
cors_rules = [
  {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://app.example.com"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
]
```

### Static website hosting

```hcl
enable_static_hosting = true

website_configuration = {
  index_document = "index.html"
  error_document = "error.html"
}

website_files = {
  "index.html" = {
    source        = "${path.root}/site/index.html"
    content_type  = "text/html"
    cache_control = "no-cache"
  }
  "assets/site.css" = {
    source        = "${path.root}/site/assets/site.css"
    content_type  = "text/css"
    cache_control = "public, max-age=3600"
  }
}
```

Static hosting is disabled by default. Set `enable_static_hosting = true` and provide `website_configuration` to enable it; website files are optional. When disabling hosting, set the toggle to `false`, set `website_configuration = null`, and clear `website_files`.

Each map key is the S3 object key; `source` points to a caller-local file. `content_type` and `cache_control` are optional. The Terraform AWS provider uploads and updates these objects when their source content changes. S3 website endpoints use HTTP, not HTTPS. Hosting a public website may require a bucket policy and relaxing relevant public-access-block settings; consider CloudFront with Origin Access Control for HTTPS and private-origin access.

### Server access logging

```hcl
logging_configuration = {
  target_bucket = "central-s3-access-logs"
  target_prefix = "app-bucket/"
}
```

The destination bucket must already exist, be in the required region, and permit S3 log delivery. The module configures logging on this bucket; it does not create or configure the target bucket.

### Other options

```hcl
transfer_acceleration_enabled = true
request_payer                 = "Requester"

block_public_access = {
  block_public_policy = false
}
```

Transfer Acceleration can incur additional charges and has bucket naming and client-endpoint requirements. With `Requester`, requesters are billed for eligible requests and must use the required request-payer header. Set `request_payer = null` to leave request-payment configuration unmanaged. Public access block settings default to `true`; change individual fields only when the use case requires it.

## Inputs

| Name | Description | Default |
|---|---|---|
| `bucket_name` | S3 bucket name. Must be globally unique. | `example-general-bucket` |
| `force_destroy` | Allow Terraform to delete a non-empty bucket. | `false` |
| `tags` | Tags applied to the bucket. | Environment/dev, ManagedBy/Terraform, Project/cloud |
| `versioning_enabled` | Enable versioning; when false, versioning is suspended. | `false` |
| `object_ownership` | `BucketOwnerEnforced`, `BucketOwnerPreferred`, or `ObjectWriter`. | `BucketOwnerEnforced` |
| `acl` | Canned ACL, used only when ownership is not `BucketOwnerEnforced`. | `private` |
| `block_public_access` | Optional per-setting public access blocks; omitted fields default to `true`. | All enabled |
| `bucket_policy` | Optional policy as HCL object or JSON string. | `null` |
| `server_side_encryption` | Default encryption algorithm, KMS key, and Bucket Key settings. | SSE-S3 enabled |
| `lifecycle_rules` | Prefix-based object lifecycle rules. | `[]` |
| `cors_rules` | Browser CORS rules. | `[]` |
| `enable_static_hosting` | Enable S3 website hosting; requires `website_configuration`. | `false` |
| `website_configuration` | Static website or redirect configuration when hosting is enabled. | `null` |
| `website_files` | Map of object keys to local file paths and optional HTTP metadata; requires static hosting to be enabled. | `{}` |
| `logging_configuration` | Optional access-log target bucket and prefix. | `null` |
| `transfer_acceleration_enabled` | Enable S3 Transfer Acceleration. | `false` |
| `request_payer` | Optional `BucketOwner` or `Requester` request-payment configuration; `null` leaves it unmanaged. | `null` |
| `aws_region` | Deprecated compatibility input; configure region in the root provider. | `ap-southeast-1` |

## Outputs

| Name | Description |
|---|---|
| `bucket_id`, `bucket_name` | Bucket name/ID. |
| `bucket_arn`, `bucket_objects_arn` | Bucket ARN and object ARN pattern. |
| `bucket_domain_name`, `bucket_regional_domain_name`, `bucket_region`, `bucket_hosted_zone_id` | Bucket endpoints and regional metadata. |
| `bucket_versioning_status` | Current configured versioning status. |
| `bucket_encryption` | Default encryption configuration, or `null` if disabled. |
| `bucket_public_access_block` | Public access block settings as a simple map. |
| `bucket_object_ownership`, `bucket_acl` | Ownership mode and configured ACL, or `null` if ACLs are disabled. |
| `bucket_tags` | Applied bucket tags, including the module-managed name tag. |
| `bucket_lifecycle_rule_ids` | Lifecycle rule IDs managed by the module. |
| `bucket_logging_configuration` | Logging target bucket and prefix, or `null` if disabled. |
| `bucket_policy_id` | Policy resource ID, or `null` when no policy is supplied. |
| `bucket_website_enabled` | Whether static website hosting is enabled. |
| `bucket_website_endpoint`, `bucket_website_domain`, `bucket_website_index_document`, `bucket_website_error_document` | Website endpoint, domain, and document settings; nullable when hosting is disabled or the setting is unset. |
| `bucket_website_object_keys` | Keys uploaded by `website_files`. |
| `bucket_acceleration_status` | Transfer Acceleration status, or `null` when disabled. |
| `bucket_request_payer` | Configured request payer, or `null` when unmanaged. |

## Safety notes

- `force_destroy = true` can permanently delete all objects, including object versions and delete markers, during Terraform destroy.
- Versioning suspension does not remove historical versions. Add an explicit lifecycle policy if old versions should expire.
- Public-access-block settings and IAM/bucket policies jointly determine whether public access is possible.
- Terraform manages one bucket policy per bucket. Supplying `bucket_policy` makes the module the owner of that policy document.
- Take care when changing encryption, lifecycle, ownership, ACL, or public-access settings on buckets with existing clients and data.
