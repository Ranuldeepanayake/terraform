# General S3 bucket caller

This root configuration creates a uniquely suffixed bucket using [`../../modules/s3`](../../modules/s3). Caller settings are passed directly as arguments in the module block in `main.tf`. A small locals block in that same file retains the generated bucket name and shared tags; there is no separate `locals.tf`, input variables, or `terraform.tfvars`. The caller settings reflect the S3 resources currently recorded in the `s3-bucket-general` Terraform state. Configure credentials and workspace settings in `provider.tf`.

## Static website and caller files

The caller includes a sample site under [`site/`](./site); website hosting is disabled by default to avoid enabling public hosting unexpectedly. Set `enable_static_hosting = true`, then set `website_configuration` and `website_files` directly in the module block in `main.tf`:

```hcl
enable_static_hosting = true

website_configuration = {
  index_document = "index.html"
  error_document = "error.html"
}

website_files = {
  for relative_path in fileset("${path.module}/site", "**") :
  relative_path => {
    source = "${path.module}/site/${relative_path}"
    content_type = lookup({
      css  = "text/css"
      gif  = "image/gif"
      html = "text/html"
      ico  = "image/x-icon"
      jpeg = "image/jpeg"
      jpg  = "image/jpeg"
      js   = "text/javascript"
      json = "application/json"
      png  = "image/png"
      svg  = "image/svg+xml"
      txt  = "text/plain"
      webp = "image/webp"
      xml  = "application/xml"
    }, lower(try(regex("\\.([^.]+)$", relative_path)[0], "")), "application/octet-stream")
    cache_control = endswith(lower(relative_path), ".html") ? "no-cache" : "public, max-age=3600"
  }
}
```

To turn hosting off, set `enable_static_hosting = false`, `website_configuration = null`, and `website_files = {}`. The endpoint is available with `terraform output -raw bucket_website_endpoint` when enabled.

Relative paths are kept as S3 object keys, so `site/assets/site.css` uploads as `assets/site.css`. Add, edit, or remove files under `site/` and Terraform will upload, update, or remove the corresponding managed S3 objects. Keep website source files in this directory, not in the module directory.

The current caller config allows public read access to objects and disables all bucket public-access blocks. The public-read policy is loaded from [`policies/bucket-policy.json`](./policies/bucket-policy.json); this exposes the bucket's objects publicly. For a private HTTPS site, use CloudFront with Origin Access Control instead of the S3 website endpoint. S3 website endpoints are HTTP-only.

## Bucket policy configuration

The caller loads its policy from [`policies/bucket-policy.json`](./policies/bucket-policy.json) using `file()` directly in the module's `bucket_policy` argument. Edit that JSON file to change the policy. Both `placeholder-bucket` and `__BUCKET_NAME__` tokens are replaced with the generated bucket name by the module. The current policy file retains the additional statements supplied for the bucket; those statements are not all present in the state snapshot.

## Configuration

The caller matches the state for the generated bucket name (`s3-app-frqsxgmb1j`), tags, `force_destroy = false`, suspended versioning, `BucketOwnerEnforced` ownership, and all four public-access-block flags set to `false`. Lifecycle rules, CORS, website hosting, access logging, Transfer Acceleration, explicit encryption configuration, and request-payment configuration are not managed in the current state. S3 applies SSE-S3 by default; this caller therefore does not add an explicit encryption resource. Website and logging settings remain disabled, and request payment is left unmanaged (`null`).

The state’s stored bucket-policy resource contains fewer statements than the current policy file. The caller preserves the supplied policy file rather than removing those additional statements; the module replaces `__BUCKET_NAME__` with the generated bucket name. Review public access carefully before applying changes.

See the [module README](../../modules/s3/README.md) for input details, examples, and S3 behavior notes. In particular, `force_destroy = true` permits Terraform to permanently delete bucket objects when destroying the bucket.
