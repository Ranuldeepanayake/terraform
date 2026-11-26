locals {
  bucket_policy_input = var.bucket_policy == null ? null : try(
    var.bucket_policy.bucket_policy,
    var.bucket_policy
  )
  bucket_policy_json_input = local.bucket_policy_input == null ? null : (
    can(keys(local.bucket_policy_input)) ? jsonencode(local.bucket_policy_input) : tostring(local.bucket_policy_input)
  )
  bucket_policy_document = local.bucket_policy_json_input == null ? null : (
    jsondecode(local.bucket_policy_json_input)
  )

  bucket_policy_statements = flatten([
    try(local.bucket_policy_document.Statement, [])
  ])

  cloudfront_distribution_arns = sort(tolist(var.cloudfront_distribution_arns))

  cloudfront_bucket_policy_statements = [
    for distribution_arn in local.cloudfront_distribution_arns : {
      Sid       = length(local.cloudfront_distribution_arns) == 1 ? "AllowCloudFrontServicePrincipal" : "CloudFrontOAC${substr(sha1(distribution_arn), 0, 16)}"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::${var.bucket_name}/*"
      Condition = {
        ArnLike = {
          "AWS:SourceArn" = distribution_arn
        }
      }
    }
    if !anytrue([
      for statement in local.bucket_policy_statements : try(
        statement.Effect == "Allow" &&
        statement.Principal.Service == "cloudfront.amazonaws.com" &&
        statement.Condition.ArnLike["AWS:SourceArn"] == distribution_arn &&
        contains(try(tolist(statement.Action), [tostring(statement.Action)]), "s3:GetObject") &&
        contains(
          [
            for resource in try(tolist(statement.Resource), [statement.Resource]) :
            replace(replace(tostring(resource), "placeholder-bucket", var.bucket_name), "__BUCKET_NAME__", var.bucket_name)
          ],
          "arn:aws:s3:::${var.bucket_name}/*"
        ),
        false
      )
    ])
  ]

  effective_bucket_policy_document = var.bucket_policy == null && length(local.cloudfront_bucket_policy_statements) == 0 ? null : {
    Version   = try(local.bucket_policy_document.Version, "2012-10-17")
    Statement = concat(local.bucket_policy_statements, local.cloudfront_bucket_policy_statements)
  }

  bucket_policy_json = local.effective_bucket_policy_document == null ? null : replace(
    replace(jsonencode(local.effective_bucket_policy_document), "placeholder-bucket", var.bucket_name),
    "__BUCKET_NAME__",
    var.bucket_name
  )
}