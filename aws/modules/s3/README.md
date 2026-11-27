# S3 bucket Terraform module

Creates and configures an S3 general-purpose bucket, including access controls, encryption, lifecycle management, browser CORS, website hosting, and access logging. Server access logs can be delivered to an S3 bucket, CloudWatch Logs, or both. The module does not create an S3 destination bucket for server access logs.

## Features

- Configurable bucket name, tags, and non-empty-bucket deletion behavior.
- Versioning, object ownership controls, optional canned ACL, and all four S3 public-access-block settings.
- Optional bucket policy supplied as an HCL object or JSON string.
- Optional CloudFront Origin Access Control (OAC) read grants scoped to distribution ARNs and merged into the supplied bucket policy.
- Default SSE-S3 or SSE-KMS encryption, including optional S3 Bucket Keys.
- Multiple prefix-based lifecycle rules for expiration, noncurrent-version cleanup, storage-class transitions, and incomplete multipart uploads.
- Optional CORS rules, static website hosting, S3 and CloudWatch server access-log delivery, Transfer Acceleration, and Requester Pays.
- Optional upload and lifecycle management of caller-owned static website files.
- Outputs for bucket identifiers, regional endpoints, configuration status, and optional website endpoints.

## Requirements

- Terraform 1.16 or later.
- AWS provider 6.67 or later (before 7.0), configured by the calling root module, with permissions to create and configure the requested S3 and CloudWatch Logs resources.

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

To allow anonymous reads only outside a sensitive key prefix, an allow statement can use `NotResource` to exclude that prefix:

```json
{
  "Effect": "Allow",
  "Principal": "*",
  "Action": "s3:GetObject",
  "NotResource": "arn:aws:s3:::__BUCKET_NAME__/private/*"
}
```

This limits only this public allow statement. Other policy statements or identity-based permissions may still grant access to the excluded objects.

### CloudFront Origin Access Control

Pass one or more CloudFront distribution ARNs through `cloudfront_distribution_arns` to add narrowly scoped `s3:GetObject` statements for CloudFront OAC requests:

```hcl
cloudfront_distribution_arns = [
  "arn:aws:cloudfront::123456789012:distribution/EXAMPLE123"
]
```

The module appends these statements to `bucket_policy`, preserving the existing statements, and creates the bucket policy if no base policy was supplied. Each generated statement trusts `cloudfront.amazonaws.com` and restricts access using the distribution ARN in `AWS:SourceArn`. If the supplied policy already contains the matching allow statement for that distribution, the module preserves it and avoids generating a duplicate. CloudFront must also have an S3 OAC configured for the origin; this input only manages the bucket-side permission. For SSE-KMS objects, the KMS key policy must separately permit the CloudFront access path.

For a single distribution, the generated statement uses the stable SID `AllowCloudFrontServicePrincipal`; with multiple distributions, each SID is derived from its ARN.

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

S3 server access logging to a bucket is enabled when `logging_configuration` is set; set `enable_server_access_logging = false` to disable delivery while retaining the destination configuration, or set `logging_configuration = null` to leave it unmanaged/disabled. For backwards compatibility, when `enable_server_access_logging` is `null` (the default), a non-null `logging_configuration` enables it. The target bucket must already exist in the same AWS Region and account and allow S3 log delivery. The module does not create or configure that destination bucket.

### Export server access logs to CloudWatch Logs

CloudWatch delivery uses AWS CloudWatch Logs vended log delivery. Enable it independently from S3 bucket delivery:

```hcl
cloudwatch_log_export_enabled = true

# Optional. Null or "" uses /aws/s3/<bucket-name>/access-logs.
cloudwatch_log_group_name        = "/aws/s3/my-app/access-logs"
cloudwatch_log_retention_in_days = 180
```

When the name is omitted or blank, the module creates `/aws/s3/<bucket-name>/access-logs`, which keeps the default distinct when multiple buckets export logs in the same account and Region. The log group is in the caller's AWS Region; AWS requires the log group to be in the same Region as the source bucket. The default retention is 180 days. CloudWatch export creates a log group, delivery source, delivery destination, and delivery. You may enable both S3 bucket delivery and CloudWatch export for the same source bucket.

The caller's IAM identity needs CloudWatch Logs permissions to create, read, update, tag, and delete the log group and delivery resources, plus `s3:AllowVendedLogDeliveryForResource` on the source bucket. The delivery API includes actions such as `logs:PutDeliverySource`, `logs:PutDeliveryDestination`, and `logs:CreateDelivery`; Terraform also needs the corresponding describe/get and delete actions to refresh, update, and destroy the resources. CloudWatch Logs vended-log ingestion and retained storage are billable; S3 server access logs are best-effort, may be delayed by hours, and are not backfilled. Disabling `cloudwatch_log_export_enabled` removes the delivery configuration and the log group managed by this module, permanently deleting its stored events. Export or retain important logs before disabling it.

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
| `bucket_name` | S3 bucket name. Must be globally unique. | Required |
| `force_destroy` | Allow Terraform to delete a non-empty bucket. | `false` |
| `tags` | Tags applied to the bucket. | `{}` |
| `versioning_enabled` | Enable versioning; when false, versioning is suspended. | `false` |
| `object_ownership` | `BucketOwnerEnforced`, `BucketOwnerPreferred`, or `ObjectWriter`. | `BucketOwnerEnforced` |
| `acl` | Canned ACL, used only when ownership is not `BucketOwnerEnforced`. | `private` |
| `block_public_access` | Optional per-setting public access blocks; omitted fields default to `true`. | All enabled |
| `bucket_policy` | Optional policy as HCL object or JSON string. | `null` |
| `cloudfront_distribution_arns` | CloudFront distribution ARNs allowed to read objects through OAC; statements are appended to the bucket policy. | `[]` |
| `server_side_encryption` | Default encryption algorithm, KMS key, and Bucket Key settings. | SSE-S3 enabled |
| `lifecycle_rules` | Prefix-based object lifecycle rules. | `[]` |
| `cors_rules` | Browser CORS rules. | `[]` |
| `enable_static_hosting` | Enable S3 website hosting; requires `website_configuration`. | `false` |
| `website_configuration` | Static website or redirect configuration when hosting is enabled. | `null` |
| `website_files` | Map of object keys to local file paths and optional HTTP metadata; requires static hosting to be enabled. | `{}` |
| `logging_configuration` | Optional S3 access-log target bucket and prefix. Target bucket must exist in the same account and Region. | `null` |
| `enable_server_access_logging` | Explicitly enable or disable S3-to-S3 server access-log delivery; when `null`, follows whether `logging_configuration` is set. | `null` |
| `cloudwatch_log_export_enabled` | Enable CloudWatch Logs vended delivery for S3 server access logs. | `false` |
| `cloudwatch_log_group_name` | CloudWatch log group name; `null` or blank uses `/aws/s3/<bucket-name>/access-logs`. | `null` |
| `cloudwatch_log_retention_in_days` | Retention for the CloudWatch log group created by the module. | `180` |
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
| `bucket_logging_configuration` | S3 logging target bucket and prefix, or `null` if S3 bucket delivery is disabled. |
| `server_access_logging_enabled` | Whether S3 server access logs are delivered to an S3 bucket. |
| `cloudwatch_log_export_enabled` | Whether S3 server access logs are exported to CloudWatch Logs. |
| `cloudwatch_log_group_name`, `cloudwatch_log_group_arn` | CloudWatch Logs destination identity, or `null` when export is disabled. |
| `cloudwatch_log_delivery_id` | CloudWatch Logs delivery ID, or `null` when export is disabled. |
| `bucket_policy_id` | Policy resource ID, or `null` when no policy is supplied. |
| `bucket_website_enabled` | Whether static website hosting is enabled. |
| `bucket_website_endpoint`, `bucket_website_domain`, `bucket_website_index_document`, `bucket_website_error_document` | Website endpoint, domain, and document settings; nullable when hosting is disabled or the setting is unset. |
| `bucket_website_object_keys` | Keys uploaded by `website_files`. |
| `bucket_acceleration_status` | Transfer Acceleration status, or `null` when disabled. |
| `bucket_request_payer` | Configured request payer, or `null` when unmanaged. |
| `cloudfront_distribution_arns` | Distribution ARNs granted object-read access by the generated policy statements. |
| `bucket_summary` | Grouped bucket identity, endpoint, tags, ownership, encryption, public-access, website, and CloudFront details. |

## Safety notes

- `force_destroy = true` can permanently delete all objects, including object versions and delete markers, during Terraform destroy.
- Versioning suspension does not remove historical versions. Add an explicit lifecycle policy if old versions should expire.
- Public-access-block settings and IAM/bucket policies jointly determine whether public access is possible.
- Terraform manages one bucket policy per bucket. Supplying `bucket_policy` makes the module the owner of that policy document.
- Take care when changing encryption, lifecycle, ownership, ACL, or public-access settings on buckets with existing clients and data.

## Importing the existing general-purpose bucket

The `s3-bucket-general` caller is configured for the existing bucket `s3-app-frqsxgmb1j` in `ap-southeast-1`. Its `random_string.bucket_suffix` must resolve to `frqsxgmb1j`; importing that random resource preserves the existing name instead of generating a new one. The caller configuration also reflects the bucket's current suspended versioning, enforced ownership, public-access-block settings, SSE-S3 encryption, self-targeted access logging, `BucketOwner` request payer, and CloudFront OAC policy.

The live S3 server access logging configuration was checked with `GetBucketLogging` and is:

```hcl
logging_configuration = {
  target_bucket = "s3-app-frqsxgmb1j"
  target_prefix = "logs/bucket-logs "
}
```

The prefix intentionally ends in a space; preserve it exactly to avoid Terraform proposing a logging configuration change. The live response also reports `TargetObjectKeyFormat.SimplePrefix`, which this module explicitly configures.

The [general-purpose caller](../../module-instances/s3-bucket-general/main.tf) keeps its optional website files in its [`site/`](../../module-instances/s3-bucket-general/site/) directory; website hosting remains disabled by default. To enable it, update the caller's module arguments with `enable_static_hosting`, `website_configuration`, and `website_files` as shown in the static website example above. Its [bucket policy](../../module-instances/s3-bucket-general/policies/bucket-policy.json) currently allows public object reads and disables public-access blocking, so the bucket's objects are publicly accessible; do not assume the CloudFront OAC grant makes this bucket private.

The current Terraform Cloud workspace already tracks `random_string.bucket_suffix`, `module.s3_bucket_general.aws_s3_bucket.this`, and the bucket's versioning, ownership controls, public-access block, and policy. Verify the workspace before importing:

```shell
terraform state list
```

The current workspace already tracks `module.s3_bucket_general.aws_s3_bucket_logging.this[0]`; no import is needed there. If that address is absent in another workspace, import the existing S3 logging configuration with either an import block in the caller's root configuration:

```hcl
import {
  to = module.s3_bucket_general.aws_s3_bucket_logging.this[0]
  id = "s3-app-frqsxgmb1j"
}
```

Then run `terraform plan` and `terraform apply` to perform the import. Alternatively, use the CLI command below from the caller directory:

```shell
terraform import 'module.s3_bucket_general.aws_s3_bucket_logging.this[0]' s3-app-frqsxgmb1j
```

In the current workspace, the other three S3 subresources not yet present in state can be imported with:

```shell
terraform import 'module.s3_bucket_general.aws_s3_bucket_server_side_encryption_configuration.this[0]' s3-app-frqsxgmb1j
terraform import 'module.s3_bucket_general.aws_s3_bucket_request_payment_configuration.this[0]' s3-app-frqsxgmb1j
```

Do not repeat an import for an address already listed in state. If using a fresh state/workspace instead, import all existing resources after initializing Terraform from the caller directory:

```shell
terraform import random_string.bucket_suffix frqsxgmb1j
terraform import 'module.s3_bucket_general.aws_s3_bucket.this' s3-app-frqsxgmb1j
terraform import 'module.s3_bucket_general.aws_s3_bucket_versioning.this' s3-app-frqsxgmb1j
terraform import 'module.s3_bucket_general.aws_s3_bucket_ownership_controls.this' s3-app-frqsxgmb1j
terraform import 'module.s3_bucket_general.aws_s3_bucket_public_access_block.this' s3-app-frqsxgmb1j
terraform import 'module.s3_bucket_general.aws_s3_bucket_policy.this[0]' s3-app-frqsxgmb1j
terraform import 'module.s3_bucket_general.aws_s3_bucket_server_side_encryption_configuration.this[0]' s3-app-frqsxgmb1j
terraform import 'module.s3_bucket_general.aws_s3_bucket_logging.this[0]' s3-app-frqsxgmb1j
terraform import 'module.s3_bucket_general.aws_s3_bucket_request_payment_configuration.this[0]' s3-app-frqsxgmb1j
```

The import ID for each listed S3 bucket subresource is the bucket name. The bucket policy in the caller must retain all currently attached statements, including the CloudFront OAC permission and S3 log-delivery grant. The CloudFront permission is generated from `cloudfront_distribution_arns`; do not duplicate it in the policy JSON. ACL, CORS, lifecycle, website, acceleration, and website-object resources are not currently configured for this bucket and should not be imported.

After import, run `terraform plan` from the caller directory and review the complete plan before applying. Import only associates remote objects with Terraform state; it does not itself change AWS resources. Do not apply a plan that changes or removes existing bucket policy statements, access logging, encryption, or public-access settings unless that change is intended.
