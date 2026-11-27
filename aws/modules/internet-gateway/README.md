# Internet Gateway module

Creates an AWS Internet Gateway and attaches it to an existing VPC. The module
adds a `ResourceType = "internet-gateway"` tag and can optionally set the
standard AWS `Name` tag. User-provided tags are retained; `ResourceType` is
managed by the module.

An Internet Gateway provides internet connectivity only when the VPC's route
tables include routes targeting it. Configure those routes separately.

## Usage

```hcl
module "internet_gateway" {
  source = "../../modules/internet-gateway"

  vpc_id = module.vpc.id
  name   = "main-internet-gateway"

  tags = {
    Environment = "dev"
  }
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---:|---|
| `vpc_id` | `string` | yes | ID of the VPC to attach the internet gateway to. |
| `name` | `string` | no | Optional value for the AWS `Name` tag. |
| `tags` | `map(string)` | no | Additional resource tags; `ResourceType` is managed by the module. |

## Outputs

| Name | Description |
|---|---|
| `id` | Internet gateway ID. |
| `arn` | Internet gateway ARN. |
| `vpc_id` | ID of the attached VPC. |
| `owner_id` | AWS account ID that owns the gateway. |
| `tags` | Tags applied to the gateway. |