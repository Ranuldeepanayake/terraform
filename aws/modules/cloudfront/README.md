# AWS CloudFront Terraform Module

Reusable Terraform module for AWS CloudFront distributions using the native AWS provider.

## Features

- S3 origins with CloudFront Origin Access Control (OAC / SigV4)
- Custom HTTP/HTTPS origins such as ALB, API Gateway, EC2, or an ingress endpoint
- Multiple origins
- Default and ordered cache behaviors
- Managed cache policies created by the module
- Managed origin request policies
- Managed response headers policies
- ACM viewer certificates
- IPv6
- HTTP/2 + HTTP/3
- Price class
- Geo restrictions
- Standard CloudFront access logging
- Custom error responses
- CloudFront Functions associations
- Lambda@Edge associations
- Existing AWS WAFv2 Web ACL attachment
- Tags
- Strong variable validation

## Important AWS requirements

### ACM
For a CloudFront distribution, the ACM certificate must be in `us-east-1`, even if the distribution's origins are elsewhere.

### WAF
AWS WAF for CloudFront is global and is normally managed through the `us-east-1` provider. This module accepts an existing Web ACL ARN through `web_acl_arn`; keeping WAF creation separate avoids forcing a provider-region architecture onto the module consumer.

### S3
For private S3 content, use OAC rather than the legacy Origin Access Identity. The module creates OAC automatically when `s3_bucket_name` is specified and `create_oac = true`.

The S3 bucket policy must separately allow the CloudFront distribution to read the bucket. This module intentionally does not create or mutate the bucket because buckets are often managed by a separate storage module.

## Example

See `examples/complete`.

## Typical EKS architecture

```text
Internet
   |
   v
Route 53
   |
   v
CloudFront
   |
   +---- AWS WAF
   |
   +---- S3 (OAC)
   |
   +---- ALB ---- EKS
                    |
                    +---- RDS
```

For an EKS application, CloudFront should normally target an ALB or another stable HTTP origin rather than individual pods.

## Cache-policy design

Prefer CloudFront cache policies and origin request policies instead of the legacy `forwarded_values` configuration. Keep the cache key as small as possible. Do not include cookies, headers, or query strings in the cache key unless the application's representation genuinely varies by them.

For APIs or authenticated dynamic applications, a common pattern is a cache policy with zero TTL plus an origin request policy that forwards the required authorization headers, cookies, and query strings.
