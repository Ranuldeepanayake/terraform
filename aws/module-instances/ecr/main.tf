
# One keyed module instance per repository; set repository_type to public to use ECR Public.
module "ecr_repositories" {
  for_each = local.repositories
  source   = "../../modules/ecr"

  providers = {
    aws        = aws
    aws.public = aws.public
  }

  repository_type      = each.value.repository_type
  name                 = each.value.name
  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push         = each.value.scan_on_push
  encryption_type      = each.value.encryption_type
  kms_key              = each.value.kms_key
  force_delete         = each.value.force_delete
  lifecycle_policy     = each.value.lifecycle_policy
  repository_policy    = each.value.repository_policy
  catalog_data         = each.value.catalog_data
  tags                 = each.value.tags
}
