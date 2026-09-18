output "iam_create_policy_ids" {
  description = "IDs of all IAM policies created by the iam_create_policy module."

  value = {
    for name, policy in module.iam_create_policy :
    name => {
      id        = policy.id
      arn       = policy.arn
      name      = policy.name
      path      = policy.path
      policy_id = policy.policy_id
    }
  }
}