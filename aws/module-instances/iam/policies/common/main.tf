# Create multiple policy objects.
module "iam_create_policy" {
  source   = "../../../../modules/iam-create-policy"
  for_each = local.policies

  name        = each.key
  description = each.value.description
  policy      = each.value.policy
  path        = each.value.path
  tags        = local.tags
}