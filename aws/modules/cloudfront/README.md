# AWS CloudFront module

This module provisions an AWS CloudFront distribution and, when requested, the DNS and TLS resources for its custom domain. It supports S3 and HTTP(S) origins, multiple cache behaviors, managed CloudFront policies, security headers, logging, WAF attachment, and edge-function associations.

## What the module manages

- **Distribution:** origins, default and ordered cache behaviors, viewer certificate, restrictions, logging, error responses, aliases, and tags.
- **S3 Origin Access Controls:** created for S3 origins when `create_oac` is enabled; existing OAC IDs can be supplied instead.
- **Cache, origin-request, and response-header policies:** created only for policies supplied to their respective maps and enabled by the corresponding `create_*_policies` input.
- **ACM certificate:** optionally requested and DNS-validated in `us-east-1` for the distribution aliases.
- **Route 53 records:** optionally publishes `A`/`AAAA` alias records to CloudFront, or a legacy `CNAME` when `route53_alias_records = false`.
- **Access logging:** optional legacy S3 logging in the distribution configuration, and/or CloudFront standard logging v2 delivered to CloudWatch Logs.
- **Existing S3 bucket policy, hosted zone, and WAF:** intentionally remain outside this module; the bucket must separately grant the distribution access.

## Origin access and permissions

For private S3 origins, CloudFront uses an Origin Access Control (OAC) to sign requests to S3 with SigV4. The module creates an OAC for an enabled S3 origin by default, or you can set `create_oac = false` and provide an existing `origin_access_control_id`. An OAC establishes how CloudFront authenticates to S3; it does **not** grant the distribution permission to read the bucket.

Grant that permission in the S3 bucket policy. Scope access to the specific distribution using its ARN as `AWS:SourceArn`, for example:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontDistributionReadOnly",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::example-private-bucket/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/EXAMPLE123"
        }
      }
    }
  ]
}
```

Replace the bucket name, account ID, and distribution ID with your values. This grants read access to objects, not permission to list or modify the bucket. The bucket policy is managed separately from this module; apply it after the distribution exists, or construct the distribution ARN from the account ID and distribution ID where appropriate. Also check for explicit denies or other bucket settings that could block access.

If the S3 objects use SSE-KMS, the KMS key policy must also allow the CloudFront service to use the key for the distribution's reads. OAC alone does not grant KMS access. For custom HTTP origins such as an ALB or API, access is instead controlled by that origin's network rules and authentication; S3 OAC does not protect custom origins.

## Requirements

- Terraform `>= 1.16.0`.
- AWS provider `6.67.0` as constrained by `versions.tf`.
- A configured default AWS provider for the distribution and Route 53 resources, plus an `aws.us_east_1` provider for ACM.
- A **pre-existing public Route 53 hosted zone** for DNS validation and/or custom-domain records. This module does not register domains or create hosted zones.
- The AWS identity must be authorized to manage CloudFront, ACM in `us-east-1`, and the selected Route 53 records.

Pass both provider configurations to the module:

```hcl
provider "aws" {
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "cdn" {
  source = "../../modules/cloudfront"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  # Other required distribution inputs omitted.
}
```

See [`examples/complete`](./examples/complete/main.tf) for a complete configuration.
See [`examples/cloudwatch-logging`](./examples/cloudwatch-logging/main.tf) for an isolated logging configuration.

## Custom domain, certificate, and DNS

To let the module request a certificate for every name in `aliases`, publish ACM validation records into the existing public zone, wait for issuance, attach the certificate to CloudFront, and publish Route 53 alias records:

```hcl
aliases                 = ["cdn.example.com"]
create_acm_certificate  = true
route53_zone_id         = "Z0123456789EXAMPLE"
create_route53_records  = true
```

The certificate is created in `us-east-1`, as required by CloudFront. Route 53 `A` alias records are created for each alias; `AAAA` records are also created when `is_ipv6_enabled = true`. ACM DNS validation is always enabled for module-created certificates. Terraform waits up to `route53_validation_wait` (default `60m`) for issuance.

For an existing certificate, leave `create_acm_certificate = false` and provide its ARN through `viewer_certificate.acm_certificate_arn`. To manage a pre-existing CNAME instead of A/AAAA aliases, set `route53_alias_records = false`; its TTL is controlled by `route53_record_ttl`.

The module does not create or alter hosted-zone NS records. Confirm that the domain is delegated to the selected public Route 53 zone before enabling DNS validation. A CNAME cannot be used at a zone apex; use the default A/AAAA alias mode for apex domains.

## CloudFront access logging

The module supports legacy CloudFront standard logging to an existing S3 bucket through `logging`, and CloudFront standard logging v2 to a CloudWatch Logs group through `cloudwatch_log_export_enabled`. These are independent destinations and can both be enabled.

The caller can use the following inputs to control CloudWatch delivery, matching the explicit toggle/name/retention pattern used by the S3 caller:

```hcl
cloudwatch_log_export_enabled    = true
cloudwatch_log_group_name        = null # Null or blank uses /aws/vendedlogs/cloudfront/<distribution-name>/access-logs.
cloudwatch_log_retention_in_days = 7
```

For an existing delivery, `cloudwatch_log_delivery_source_name` and `cloudwatch_log_delivery_destination_name` can be set to its current CloudWatch names so the module can import and manage those resources without replacing them. If omitted, the module derives names for a new delivery.

CloudFront vended-log delivery APIs must be called in `us-east-1`; this module uses the required `aws.us_east_1` provider for the log group and delivery resources. The log group is therefore also created in `us-east-1`. The default retention is 180 days; the caller explicitly sets 7 days. CloudWatch Logs vended-log ingestion and retained storage are billable, and delivery is not instantaneous.

Legacy S3 logging remains off unless `logging` is configured. Its destination bucket must already exist and satisfy CloudFront's S3 logging requirements. CloudWatch export does not require the legacy `logging` input. Disabling CloudWatch export removes the delivery source, destination, delivery, and module-managed log group, which permanently deletes stored events in that group. Export or retain important logs before turning it off.

The caller's IAM identity needs CloudWatch Logs delivery permissions including `logs:PutDeliverySource`, `logs:PutDeliveryDestination`, `logs:CreateDelivery`, the corresponding get/describe/delete actions, and log-group create/retention/delete permissions in `us-east-1`. AWS automatically creates the log-group resource policy for the `delivery.logs.amazonaws.com` service when delivery begins, provided the caller also has `logs:PutResourcePolicy`, `logs:DescribeResourcePolicies`, and `logs:DescribeLogGroups`. AWS recommends the `/aws/vendedlogs/` prefix when using account-level resource policies. See [CloudFront standard logging v2](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logging.html) and [CloudWatch Logs delivery permissions](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AWS-logs-infrastructure-V2-CloudWatchLogs.html).

## Existing distribution import

The caller in [`aws/module-instances/cloudfront`](../../module-instances/cloudfront/main.tf) describes distribution `E1BDLID84MOL0G` and its existing CNAME. First initialize from that directory:

```powershell
terraform init
```

Import the existing distribution, OAC, and CNAME into the caller's state before planning. Replace `YOUR_EXISTING_OAC_ID` with the ID of the OAC named in the caller's `origins` block:

```powershell
terraform import module.cloudfront.aws_cloudfront_distribution.this E1BDLID84MOL0G
terraform import 'module.cloudfront.aws_cloudfront_origin_access_control.this["s3-app-frqsxgmb1j.s3.ap-southeast-1.amazonaws.com-mqv08rjtn69"]' YOUR_EXISTING_OAC_ID
terraform import 'module.cloudfront.aws_route53_record.distribution_cname["cdn.s3-app.ranul.click"]' 'Z0233745IB90EWVKK2K1_cdn.s3-app.ranul.click_CNAME'
terraform import 'module.cloudfront.aws_cloudwatch_log_delivery_source.cloudfront_access_logs[0]' CreatedByCloudFront-E1BDLID84MOL0G-ACCESS_LOGS
terraform plan
```

Review the plan for unexpected changes before applying. The caller deliberately reuses the existing ACM certificate and managed cache policy; it does not create duplicate certificate resources. Do not apply before importing the existing DNS record, OAC, distribution, and logging source, because they already exist in AWS.

The existing distribution currently has legacy S3 logging disabled but already has CloudFront standard logging v2 delivering to CloudWatch Logs. The live configuration uses the `s3-app` log group in `us-east-1`, seven-day retention, source `CreatedByCloudFront-E1BDLID84MOL0G-ACCESS_LOGS`, destination `CF-E1BDLID84MOL0G-s3-app-1782548320848`, and delivery ID `FcAD6u9OVoG5bJYQ`.

The caller intentionally leaves the CloudWatch log group and delivery destination names unset. It will add a second CloudFront logging destination using the generated group `/aws/vendedlogs/cloudfront/s3-app/access-logs`, while the existing `s3-app` delivery continues unchanged. CloudFront supports multiple logging destinations. This means additional CloudWatch ingestion and storage charges. The source name defaults to the existing distribution source, so import that source before planning; do not import the current `s3-app` group, destination, or delivery into this caller, because they are not the destination configured by these defaults.

The existing destination ARN ends in `:*` (for example, `...:log-group:s3-app:*`). When managing that existing destination, preserve the suffix; changing its ARN while a delivery references it causes AWS to reject the update. This caller does not manage that existing destination.

## Module layout

- `main.tf` — CloudFront distribution and its behaviors.
- `origins.tf` — S3 Origin Access Controls.
- `cache.tf` — cache and origin-request policies.
- `security.tf` — response-header policies.
- `domain.tf` — ACM certificate validation and Route 53 records.
- `logging.tf` — optional CloudFront standard logging v2 delivery to CloudWatch Logs.
- `locals.tf` — derived origin and certificate values and the AWS region lookup.
- `variables.tf`, `outputs.tf`, `versions.tf` — module interface and provider requirements.

## Outputs

The module exposes the distribution ID, ARN, CloudFront domain and HTTPS URL, aliases, enabled state, status, hosted-zone ID, ETag, and last-modified timestamp. `origins` maps each configured origin ID to its domain name.

Policy outputs include IDs for policies created by the module and `effective_behavior_policy_ids`, which resolves the actual cache, origin-request, and response-header policy IDs for the `default` behavior and each ordered behavior. `effective_oac_ids` maps S3 origin IDs to their OAC IDs, including externally supplied OACs; `oac_ids` remains limited to OACs created by the module. DNS and certificate outputs include the ACM certificate ARN and Route 53 record FQDNs.

Logging outputs expose whether CloudWatch export is enabled, the configured log group name and ARN, the delivery source and destination names, and the delivery ID. These identifiers are `null` when CloudWatch export is disabled.

## Origins, CORS, and caching

These settings solve different problems, but work together on each cache behavior:

- **Origin settings** tell CloudFront where and how to fetch content when it needs to contact a backend. An origin is selected by its map key, which becomes its `origin_id`; `default_behavior.target_origin_id` and each ordered behavior's `target_origin_id` must match an enabled origin. Use `s3_bucket_name` for an S3 REST origin or `domain_name` for a custom HTTP(S) origin. Custom origins also need an appropriate `origin_protocol_policy`. For private S3 content, OAC signs origin requests; it controls CloudFront-to-S3 access, not browser CORS.
- **Cache policy** defines what contributes to the cache key and how long a response can be cached. Requests with different cache keys can have separate cached objects; requests that share a key can receive the same cached response. Include a header, cookie, or query parameter in the cache key only when the origin's response actually varies by it. A larger key reduces cache hits and can increase origin traffic.
- **Origin request policy** forwards selected headers, cookies, and query strings to the origin without adding them to the cache key. Use it for values the origin needs to process but that do not change the representation being cached. Forwarding a value without including it in the cache key is unsafe if the origin response varies by that value: CloudFront could serve one request's response to another request.
- **CORS** is a browser-enforced permission check for frontend code making cross-origin requests. It is not authentication or a substitute for OAC, bucket policies, or origin access controls. Configure the origin to return the required `Access-Control-Allow-*` headers, or attach a CloudFront response headers policy with `cors_config`. If the origin generates CORS headers dynamically, ensure the cache key varies on the relevant `Origin` request header (and any other request inputs used to produce the CORS response), or use a response headers policy that supplies consistent headers. Otherwise a cached response may contain CORS headers for a different requesting site.

For browser-based cross-origin requests, also allow `OPTIONS` in the behavior's `allowed_methods` when the browser sends preflight requests. If the origin must inspect preflight headers or methods, forward the required request headers (for example `Origin`, `Access-Control-Request-Method`, and `Access-Control-Request-Headers`) and configure the origin or response headers policy to allow them. Add these values to the cache key only if the resulting response varies and is safe to cache separately; alternatively, disable caching for preflight responses. For S3 origins, configure the bucket's CORS rules separately when S3 itself must return CORS headers.

### Choosing policy settings

- **Static public files:** use a cache policy with a long TTL and no cookies or query strings in the cache key unless the URL convention requires them. Forward no unnecessary request values.
- **Dynamic API responses:** use a short or zero-TTL cache policy when responses should not be reused, and an origin request policy to forward the authorization header, required cookies, and query strings. Do not cache personalized responses unless the cache key safely distinguishes users or the response is otherwise public.
- **Public API responses with CORS:** if the CORS response is the same for every allowed site, a response headers policy can add consistent CORS headers. If the origin reflects the request's `Origin`, forward `Origin` and include it in the cache key (or avoid caching those responses).

The module supports either an existing policy ID (such as an AWS-managed policy) or a name of a policy declared in `cache_policies`, `origin_request_policies`, or `response_headers_policies`. These settings are made per default or ordered cache behavior; ordered behaviors are evaluated before the default behavior.

## Design and operational notes

- Prefer cache policies and origin-request policies over legacy `forwarded_values`.
- Keep the cache key small; forward cookies, headers, and query strings only when the application requires them.
- CloudFront OAC does not update the S3 bucket policy. Grant the distribution's service principal access separately.
- For private content, use OAC rather than legacy Origin Access Identity.
- AWS provider `6.67.0` exposes `origin_read_timeout` for custom HTTP origins but not for S3 origins; the S3 timeout reported by AWS is therefore not configurable through this module.
- CloudFront WAFv2 is global. Supply an existing Web ACL ARN through `web_acl_arn`; WAF creation is intentionally separate.
- Lambda@Edge functions must meet AWS region and versioning requirements.
- `retain_on_delete` controls whether CloudFront retains a disabled distribution when Terraform destroys it; it does not prevent configuration changes.
