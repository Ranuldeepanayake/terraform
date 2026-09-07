# VPC Endpoint Terraform Module

A reusable Terraform module for creating AWS VPC endpoints.

The module supports both **Interface** and **Gateway** VPC endpoints. For Interface endpoints, it optionally creates a dedicated security group or allows existing security groups to be supplied by the caller.

## Features

* Supports `Interface` and `Gateway` VPC endpoints.
* Configurable AWS service name.
* Supports multiple subnets for Interface endpoints.
* Supports existing security groups.
* Optionally creates a security group for Interface endpoints.
* Security group ingress and egress rules are defined by the caller.
* Supports private DNS for Interface endpoints.
* Supports custom tags.
* Exposes endpoint, DNS, network interface, and security group information through outputs.

## Module Structure

```text
modules/
└── vpc-endpoint/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    └── README.md
```

## Usage

### Interface Endpoint with an Existing Security Group

```hcl
module "secrets_manager_endpoint" {
  source = "./modules/vpc-endpoint"

  endpoint_name = "secrets-manager"

  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.secretsmanager"

  vpc_endpoint_type = "Interface"

  subnet_ids = module.vpc.private_subnet_ids

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Interface Endpoint with a New Security Group

The module can create the security group when:

```hcl
create_security_group = true
```

Security-group rules are supplied by the caller.

```hcl
module "secrets_manager_endpoint" {
  source = "./modules/vpc-endpoint"

  endpoint_name = "secrets-manager"

  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.secretsmanager"

  vpc_endpoint_type = "Interface"

  subnet_ids = module.vpc.private_subnet_ids

  create_security_group = true

  security_group_ingress_rules = [
    {
      description                  = "HTTPS from Lambda"
      referenced_security_group_id = aws_security_group.lambda.id
    }
  ]

  security_group_egress_rules = [
    {
      description = "Allow outbound traffic"
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  ]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

The default values for the ingress rule are:

```text
protocol   = tcp
from_port  = 443
to_port    = 443
```

The default values for the egress rule are:

```text
protocol   = -1
from_port  = 0
to_port    = 0
```

The rules themselves default to an empty list, meaning **no security-group rules are automatically created**.

This allows the caller to explicitly define the required security policy.

## Using an Existing Security Group

If the endpoint should use an existing security group, set:

```hcl
security_group_ids = [
  aws_security_group.vpc_endpoints.id
]
```

and leave:

```hcl
create_security_group = false
```

For example:

```hcl
module "secrets_manager_endpoint" {
  source = "./modules/vpc-endpoint"

  endpoint_name = "secrets-manager"

  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.secretsmanager"

  subnet_ids = module.vpc.private_subnet_ids

  security_group_ids = [
    aws_security_group.shared_vpc_endpoints.id
  ]
}
```

The module does not modify the existing security group or its rules.

## Creating a Security Group

Set:

```hcl
create_security_group = true
```

The module will create a security group in the specified VPC.

The security group's name prefix defaults to:

```text
sg-vpc-endpoint-<endpoint_name>
```

A custom name prefix can be supplied through:

```hcl
security_group_name = "my-custom-prefix-"
```

Because the module uses `name_prefix`, Terraform/AWS can append a unique suffix to the security-group name.

### Security Group Rules

Security-group rules are deliberately managed through module inputs.

#### Ingress

```hcl
security_group_ingress_rules = [
  {
    description                  = "HTTPS from Lambda"
    from_port                    = 443
    to_port                      = 443
    protocol                     = "tcp"
    referenced_security_group_id = aws_security_group.lambda.id
  }
]
```

CIDR-based rules are also supported:

```hcl
security_group_ingress_rules = [
  {
    description = "HTTPS from private subnet"
    cidr_ipv4   = "10.0.0.0/16"
  }
]
```

IPv6 CIDRs are supported through:

```hcl
cidr_ipv6 = "2001:db8::/64"
```

#### Egress

For unrestricted outbound traffic:

```hcl
security_group_egress_rules = [
  {
    description = "Allow outbound traffic"
    protocol    = "-1"
    cidr_ipv4   = "0.0.0.0/0"
  }
]
```

More restrictive rules can be supplied when required by the architecture.

## Gateway Endpoint

The module also supports Gateway endpoints.

For example, an S3 endpoint:

```hcl
module "s3_endpoint" {
  source = "./modules/vpc-endpoint"

  endpoint_name = "s3"

  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

  tags = {
    Environment = "production"
  }
}
```

Gateway endpoints do not use:

* `subnet_ids`
* `security_group_ids`
* `private_dns_enabled`

These settings are only applicable to Interface endpoints.

> **Note:** If Gateway endpoint support is required, the module should expose a `route_table_ids` variable and pass it to `aws_vpc_endpoint.route_table_ids`.

## Interface vs Gateway Endpoints

### Interface Endpoint

An Interface endpoint creates **Elastic Network Interfaces (ENIs)** in the selected subnets.

```text
VPC
│
├── Private Subnet A
│     └── Endpoint ENI
│
├── Private Subnet B
│     └── Endpoint ENI
│
└───────────────► AWS Service
```

Interface endpoints are commonly used for services such as:

* Secrets Manager
* Systems Manager
* ECR
* CloudWatch Logs
* STS
* KMS

Interface endpoints use security groups and can use private DNS.

### Gateway Endpoint

Gateway endpoints provide routing through the VPC route tables rather than creating ENIs.

They are primarily used for:

* Amazon S3
* Amazon DynamoDB

Gateway endpoints do not use security groups.

## Multiple AWS Services

A VPC endpoint represents **one AWS service**.

For example, Secrets Manager and ECR require separate endpoints:

```text
VPC
│
├── Interface Endpoint
│     └── Secrets Manager
│
├── Interface Endpoint
│     └── ECR API
│
└── Interface Endpoint
      └── CloudWatch Logs
```

The same security group can be reused by multiple Interface endpoints when appropriate.

For example:

```hcl
module "secrets_manager_endpoint" {
  source = "./modules/vpc-endpoint"

  endpoint_name = "secrets-manager"

  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.secretsmanager"

  subnet_ids = module.vpc.private_subnet_ids

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]
}

module "ecr_endpoint" {
  source = "./modules/vpc-endpoint"

  endpoint_name = "ecr"

  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.ecr.api"

  subnet_ids = module.vpc.private_subnet_ids

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]
}
```

## Variables

| Variable                       | Type           | Default             | Description                                  |
| ------------------------------ | -------------- | ------------------- | -------------------------------------------- |
| `vpc_id`                       | `string`       | —                   | ID of the VPC                                |
| `service_name`                 | `string`       | —                   | AWS service name                             |
| `vpc_endpoint_type`            | `string`       | `"Interface"`       | Endpoint type: `Interface` or `Gateway`      |
| `endpoint_name`                | `string`       | —                   | Name of the VPC endpoint                     |
| `subnet_ids`                   | `list(string)` | `[]`                | Subnets for Interface endpoints              |
| `security_group_ids`           | `list(string)` | `[]`                | Existing security groups                     |
| `create_security_group`        | `bool`         | `false`             | Whether to create a security group           |
| `security_group_name`          | `string`       | `null`              | Optional security-group name prefix          |
| `security_group_description`   | `string`       | default description | Security-group description                   |
| `security_group_ingress_rules` | `list(object)` | `[]`                | Ingress rules for the created security group |
| `security_group_egress_rules`  | `list(object)` | `[]`                | Egress rules for the created security group  |
| `private_dns_enabled`          | `bool`         | `true`              | Enable private DNS for Interface endpoints   |
| `tags`                         | `map(string)`  | `{}`                | Tags applied to resources                    |

## Outputs

### `vpc_endpoint_id`

The ID of the created VPC endpoint.

### `vpc_endpoint_arn`

The ARN of the created VPC endpoint.

### `vpc_endpoint_type`

The endpoint type (`Interface` or `Gateway`).

### `vpc_id`

The VPC containing the endpoint.

### `service_name`

The AWS service associated with the endpoint.

### `state`

The current endpoint state.

Examples include:

```text
pending
available
deleting
deleted
```

### `subnet_ids`

Subnet IDs associated with the Interface endpoint.

### `security_group_ids`

Security groups attached to the Interface endpoint.

### `endpoint_security_group_ids`

All security groups associated with the endpoint, including:

* Existing security groups supplied by the caller
* The security group created by the module, if enabled

This is the recommended output for consumers that need the endpoint's security groups.

### `created_security_group_id`

ID of the security group created by this module.

Returns `null` when the module does not create one.

### `created_security_group_name`

Actual AWS name of the security group created by this module.

Returns `null` when the module does not create one.

### `created_security_group_arn`

ARN of the security group created by this module.

Returns `null` when the module does not create one.

### `network_interface_ids`

Network interface IDs created for an Interface endpoint.

### `dns_entries`

DNS entries associated with an Interface endpoint.

### `private_dns_enabled`

Whether private DNS is enabled.

### `endpoint_name`

The logical endpoint name supplied to the module.

## Requirements

Terraform:

```text
>= 1.5.0
```

AWS provider:

```text
>= 5.0
```

## Security Considerations

The module intentionally does **not** automatically create permissive security-group rules.

For Interface endpoints, the recommended approach is to restrict HTTPS access to the workloads that require the endpoint.

For example:

```hcl
security_group_ingress_rules = [
  {
    description                  = "HTTPS from Lambda"
    referenced_security_group_id = aws_security_group.lambda.id
  }
]
```

Avoid unnecessarily broad rules such as:

```hcl
cidr_ipv4 = "0.0.0.0/0"
```

for endpoint ingress.

The endpoint's security group should generally allow TCP/443 from the security groups or CIDR ranges of workloads that need to access the AWS service.

## Example: Lambda + Secrets Manager

A typical architecture is:

```text
                    VPC
                     │
          ┌──────────┴──────────┐
          │                     │
    Private Subnet A      Private Subnet B
          │                     │
       Lambda                Lambda
          │                     │
          └──────────┬──────────┘
                     │
                   HTTPS
                   TCP/443
                     │
                     ▼
          Secrets Manager
          Interface Endpoint
                     │
                     ▼
             AWS Secrets Manager
```

The Lambda security group is allowed to access the endpoint security group on TCP/443.

The Lambda can then use the normal AWS SDK:

```javascript
const secretResponse = await secretsManager.send(
    new GetSecretValueCommand({
        SecretId: SECRET_ID
    })
);
```

No public internet access or NAT Gateway is required for the Lambda to access Secrets Manager through the Interface endpoint.

## License

This module is provided for internal infrastructure use.
