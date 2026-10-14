locals {
  bucket_policy_input = var.bucket_policy == null ? null : try(
    var.bucket_policy.bucket_policy,
    var.bucket_policy
  )
  bucket_policy_json_input = local.bucket_policy_input == null ? null : (
    can(jsondecode(local.bucket_policy_input)) ? local.bucket_policy_input : jsonencode(local.bucket_policy_input)
  )
  bucket_policy_document = local.bucket_policy_json_input == null ? null : (
    jsondecode(local.bucket_policy_json_input)
  )
  bucket_policy_json = local.bucket_policy_document == null ? null : replace(
    replace(jsonencode(local.bucket_policy_document), "placeholder-bucket", var.bucket_name),
    "__BUCKET_NAME__",
    var.bucket_name
  )
}