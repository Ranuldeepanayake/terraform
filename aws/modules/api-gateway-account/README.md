# api-gateway-account

Terraform module that configures the account-level API Gateway CloudWatch Logs setting. This is a one-time bootstrap — apply it once per AWS account/region before deploying any API Gateway stacks.

## Background

REST API stages can write execution logs to CloudWatch, but API Gateway requires an IAM role to be registered at the account level before it can do so. This is done via `aws_api_gateway_account`, which is a singleton resource — there is only one account-level setting per region. This module creates the IAM role and registers it.

Without this, any stage configured with `logging_level = "INFO"` or `"ERROR"` will deploy successfully but produce no log output.

## Usage

```hcl
module "api_gateway_account" {
  source = "../../modules/api-gateway-account"

  role_name = "my-project-api-gateway-cloudwatch"
  tags      = { ManagedBy = "terraform" }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `role_name` | Name of the IAM role granted CloudWatch Logs write access | `string` | `"api-gateway-cloudwatch-logs"` | no |
| `tags` | Tags applied to the IAM role | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `cloudwatch_role_arn` | ARN of the IAM role registered as the API Gateway CloudWatch Logs role |
| `cloudwatch_role_name` | Name of the IAM role |

## Notes

### Singleton constraint

`aws_api_gateway_account` is a singleton — one per AWS account/region. Only one Terraform stack should manage it. If a second stack attempts to create it, the second apply will silently overwrite the first's role ARN, and destroying either stack will unset the account configuration for all API Gateways in the region.

Apply this module in its own isolated stack and treat it as shared infrastructure, not as part of any individual API deployment.

### Apply order

This stack must be applied before any API Gateway stack that enables execution logging. There is no hard Terraform dependency between them — the constraint is operational: logging will silently fail until the account role is registered.
