# data "aws_caller_identity" "current" {}

# data "terraform_remote_state" "eks" {
#   backend = "remote"

#   config = {
#     organization = "ranuldeepanayake"

#     workspaces = {
#       name = "aws-dev-eks"
#     }
#   }
# }

# data "aws_iam_policy_document" "pod_identity_trust" {
#   statement {
#     actions = ["sts:AssumeRole", "sts:TagSession"]

#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "aws:SourceAccount"
#       values   = [data.aws_caller_identity.current.account_id]
#     }

#     condition {
#       test     = "ArnEquals"
#       variable = "aws:SourceArn"
#       values   = [data.terraform_remote_state.eks.outputs.cluster_arn]
#     }
#   }
# }