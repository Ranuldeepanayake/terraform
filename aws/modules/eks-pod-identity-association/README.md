# EKS Pod Identity Association Module

Creates an AWS EKS Pod Identity association between a Kubernetes service account and an existing IAM role.

This module creates only the association. It does not create the IAM role, role trust policy, permissions policy, Kubernetes namespace, service account, EKS cluster, or Pod Identity Agent add-on.

## Prerequisites

- An EKS cluster with EKS Pod Identity enabled.
- The EKS Pod Identity Agent add-on installed and healthy on the cluster.
- An IAM role in the same account as the cluster, unless using the optional cross-account target role flow.
- The IAM role trust policy must allow the EKS Pod Identity service principal to assume it and create session tags. At minimum, trust `pods.eks.amazonaws.com` for `sts:AssumeRole` and `sts:TagSession`.
- The workload's Kubernetes namespace and service account should exist before the workload uses the association.

Example trust relationship for the IAM role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "pods.eks.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }
  ]
}
```

Attach the workload's AWS permissions to this IAM role. For example, a role used for IAM database authentication needs an `rds-db:connect` permission scoped to the RDS DB resource ID and database username.

## Usage

```hcl
module "app_pod_identity" {
  source = "../../modules/eks-pod-identity-association"

  cluster_name    = "eks-cluster"
  namespace       = "application"
  service_account = "app"
  role_arn        = "arn:aws:iam::104322896078:role/AppPodIdentityRole"

  disable_session_tags = false
  target_role_arn      = null

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

The module adds `ResourceType = "eks-pod-identity-association"` to the supplied tags.

For cross-account access, set `target_role_arn` to the target account role and configure the target role trust policy and permissions for the EKS Pod Identity role as required. Otherwise, leave it `null`.

## Inputs

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `cluster_name` | `string` | Yes | Name of the EKS cluster. |
| `namespace` | `string` | Yes | Kubernetes namespace containing the service account. |
| `service_account` | `string` | Yes | Kubernetes service account associated with the IAM role. |
| `role_arn` | `string` | Yes | Existing IAM role ARN used by EKS Pod Identity. |
| `disable_session_tags` | `bool` | No | Disables session tags when `true`; defaults to `false`. |
| `target_role_arn` | `string` | No | Optional target role ARN for cross-account role assumption; defaults to `null`. |
| `tags` | `map(string)` | No | Additional tags for the association; defaults to `{}`. |

## Outputs

| Name | Description |
| --- | --- |
| `association_id` | ID of the EKS Pod Identity association. |
| `association_arn` | ARN of the EKS Pod Identity association. |
| `role_arn` | IAM role ARN used by the association. |

## Provider

The caller must configure the AWS provider. The module declares a dependency on `hashicorp/aws` but does not pin its version; pin the provider version in the root configuration.
