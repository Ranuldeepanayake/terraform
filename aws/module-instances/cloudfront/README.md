# Existing CloudFront distribution

This caller models distribution `E1BDLID84MOL0G` using its current AWS configuration, and manages its Origin Access Control. It reuses the existing certificate and AWS-managed `CachingOptimized` policy. It also manages the existing CNAME in the `ranul.click` public hosted zone. The S3 bucket is intentionally not managed here; its module and caller will be updated separately.

The CloudFront module requires the default `ap-southeast-1` AWS provider and an `aws.us_east_1` provider for ACM. The supplied profile must be allowed to manage CloudFront, ACM, and the Route 53 hosted zone.

From this directory, initialize Terraform and import the existing OAC and CNAME into Terraform state:

```powershell
terraform init
terraform import 'module.cloudfront.aws_cloudfront_origin_access_control.this["s3-app-frqsxgmb1j.s3.ap-southeast-1.amazonaws.com-mqv08rjtn69"]' E3LYWZ8VKRFCJX
terraform import 'module.cloudfront.aws_route53_record.distribution_cname["cdn.s3-app.ranul.click"]' 'Z0233745IB90EWVKK2K1_cdn.s3-app.ranul.click_CNAME'
terraform plan
```

The distribution is already in this caller's current state. If using a fresh state, also run `terraform import module.cloudfront.aws_cloudfront_distribution.this E1BDLID84MOL0G`.

The bucket's current OAC is `E3LYWZ8VKRFCJX`, named `oac-s3-app-frqsxgmb1j.s3.ap-southeast-1.amazonaws.co-mqv0b8xxkk0`, configured for S3 with SigV4 and `always` signing. Its existing bucket policy already grants this distribution `s3:GetObject`; this caller does not manage or rewrite the bucket policy. Note that the same policy also contains a public `s3:GetObject` grant, and AWS reports the bucket policy as public. This caller preserves that existing access; review it separately if public reads are not intentional.

Import the CNAME before planning or applying: it already exists in Route 53. Review the plan before applying, especially any changes to the distribution's S3 origin. The existing certificate was issued for a wildcard that covers this alias, so this caller does not request or replace it.

The origin bucket is `s3-app-frqsxgmb1j`. It is referenced by the CloudFront origin configuration but is not managed or imported by this caller. Import and manage the bucket through its dedicated S3 module/caller when that configuration is updated.

### Optional imports for future ownership changes

The current caller only passes the existing ACM certificate ARN and AWS-managed cache policy ID to the distribution. Neither has a Terraform resource address in the current configuration, so do not run the following imports unless you first add matching resource configuration.

If you later want Terraform to manage the existing ACM certificate directly, add an `aws_acm_certificate` resource in this caller using the `aws.us_east_1` provider and configuration matching that certificate, then point `viewer_certificate.acm_certificate_arn` at the resource. Import it with:

```powershell
terraform import aws_acm_certificate.viewer arn:aws:acm:us-east-1:104322896078:certificate/e180dd3c-6035-4b3b-848a-46264799da9f
```

The certificate currently attached to the distribution is `*.ranul.click`, with `*.s3-app.ranul.click` as an additional name. Verify all certificate options and tags in ACM before adding the resource and planning; an inaccurate resource configuration could propose replacing the certificate.

The current cache policy, `658327ea-f89d-4fab-a63d-7e88639e58f6`, is AWS-managed `CachingOptimized`. Keep referencing it by `cache_policy_id`; AWS-managed policies are not owned by this account and should not be imported. If a future distribution uses a **customer-managed** cache policy and you add its matching definition under the module's `cache_policies` map, import that policy at the module's managed-policy address:

```powershell
terraform import 'module.cloudfront.aws_cloudfront_cache_policy.managed["<policy-map-key>"]' <customer-managed-cache-policy-id>
```

Replace both placeholders with the configured map key and the policy ID. The resource must be declared in configuration first, and its name and settings must match the existing policy.
