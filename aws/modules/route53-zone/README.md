# Route 53 Hosted Zone Terraform Module

Creates or adopts a public or private Route 53 hosted zone and manages DNS record sets declared by the caller. Records are keyed by stable caller-defined map keys so callers can keep DNS data in JSON, load it with `jsondecode(file(...))`, and import existing record sets without changing their Terraform addresses when the records themselves are edited.

The module supports simple records, aliases, and Route 53 weighted, latency, failover, geolocation, geoproximity, CIDR, and multivalue routing. It does not create ACM certificates, Route 53 health checks, CIDR collections, or the VPCs referenced by private hosted zones.

## Requirements and behavior

- Terraform 1.16 or later.
- AWS provider 6.x configured by the calling root module with Route 53 and CloudWatch Logs permissions when query logging is enabled.
- The caller must pass the `aws.us_east_1` provider alias to this module, even when query logging is disabled.
- Public zones use public DNS and can use a reusable delegation set. Their registrar or parent zone must delegate to the assigned Route 53 name servers.
- Private zones require at least one existing VPC association. VPC IDs and optional regions are passed to the hosted-zone resource; the module does not create VPCs.
- `force_destroy` defaults to `false`. When enabled, deleting a zone can delete all records managed outside this module too.
- The AWS-created `NS` and `SOA` records are not managed by the module. Do not define them in the JSON record map.
- A DNS record set is the complete set of values for a name, type, and routing identifier. Import an existing set before managing it; do not model one existing set as multiple Terraform resources.
- The caller controls exactly which records are managed. Records omitted from `records` are not imported, changed, or removed by this module.
- Public DNS query logging is optional and disabled by default. When enabled, it creates a CloudWatch log group and log resource policy in `us-east-1`, then attaches a Route 53 query logging configuration. Private hosted zones are not supported by this query-logging feature.

## Record ownership and drift

This module does not inventory or adopt every record in a hosted zone. It manages only the record sets explicitly present in the caller's `records` map. Records created by other services can coexist in the same zone and are left alone as long as they do not conflict with a record set declared here.

- If another service creates a new, distinct record set, this module does not treat it as drift and will not change it. Add it to the JSON map and import it only if this Terraform caller is intended to own it.
- If another service changes or deletes a record set already declared in the map, the next `terraform plan` reports drift and proposes reconciling AWS to the JSON-defined configuration. Review the plan and coordinate ownership before applying; otherwise the apply may undo the service's change.
- A Route 53 record set is identified by hosted zone, record name, type, and (for routing-policy records) set identifier. Keep exactly one Terraform state/caller as the owner of each complete record set. Two callers managing the same set can overwrite one another or produce conflicting plans. `allow_overwrite` affects creation behavior; it does not resolve duplicate ownership.
- Removing a record from the JSON map makes Terraform plan to delete that record if this state manages it. Keep record definitions in the map for as long as this caller owns them, or deliberately transfer state ownership before removing them.
- Keep `force_destroy = false`. When enabled, destroying the hosted zone can remove records created by services and records not otherwise managed by this Terraform caller.

For a shared zone, a safe pattern is for each service to manage only its own distinct record sets in its own Terraform state, while one designated owner manages the hosted zone itself. If a central caller should own all DNS records instead, have services contribute their record definitions to its version-controlled JSON map and create no separate Terraform resources for those same records.

## Basic caller configuration

```hcl
module "public_zone" {
  source = "../../modules/route53-zone"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  zone_name     = "example.com"
  comment       = "Public application DNS"
  private_zone  = false
  force_destroy = false

  records = jsondecode(file("${path.module}/records/example.com.json"))
}
```

The module itself does not configure AWS credentials or a provider region. Configure both the default provider and the `us_east_1` alias in the caller, then pass them as shown. The default provider region is also used for private-zone VPC associations when no per-association region is supplied.

## Public DNS query logging

Set `enable_query_logging = true` to send Route 53's public DNS queries to CloudWatch Logs. The log group must be in `us-east-1`, regardless of the hosted zone caller's default region. The caller must configure and pass the `us_east_1` provider alias whether logging is enabled or not:

```hcl
provider "aws" {
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "public_zone" {
  source = "../../modules/route53-zone"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  zone_name                    = "example.com"
  private_zone                 = false
  enable_query_logging         = true
  query_log_retention_in_days  = 7
}
```

`query_log_group_name` is optional. If omitted, the module creates `/aws/route53/<zone-name>/query-logs`. The resource-scoped CloudWatch Logs policy grants only `route53.amazonaws.com` permission to write to that log group. The caller needs `route53:CreateQueryLoggingConfig`, `route53:GetQueryLoggingConfig`, and `route53:DeleteQueryLoggingConfig`, plus CloudWatch Logs permissions to create, describe, set retention on, and delete the log group and to put, describe, and delete the resource policy in `us-east-1`. The preflight command below additionally needs `route53:ListQueryLoggingConfigs`.

Query logs include queried domain names, record types, response codes, resolver IP addresses, and related request metadata. They are not a complete record of end-user lookups: recursive resolver caching can satisfy requests without querying Route 53. Route 53 does not charge for query logging itself; CloudWatch Logs ingestion and storage are billed, so choose an appropriate retention period. Disabling the feature removes its query configuration, policy, and log group, including the log data stored in that group. This feature applies only to public hosted zones.

## Private hosted-zone configuration

For private DNS, set `private_zone = true` and provide at least one existing VPC:

```hcl
module "private_zone" {
  source = "../../modules/route53-zone"

  zone_name    = "internal.example.com"
  comment      = "Private service discovery"
  private_zone = true

  vpc_associations = [
    {
      vpc_id     = "vpc-0123456789abcdef0"
      vpc_region = "ap-southeast-1"
    },
    {
      vpc_id     = "vpc-0fedcba9876543210"
      vpc_region = "us-east-1"
    }
  ]
}
```

The caller's AWS credentials must be permitted to associate each listed VPC. Cross-account private-zone associations may require a separate authorization and association workflow; this module does not create that authorization.

## JSON DNS record map

Each map key becomes the stable Terraform key in `aws_route53_record.this["<key>"]`. Each value is one complete record set. Use `name`, `type`, and either `records` plus `ttl`, or an `alias` object. The caller should keep JSON data separate from Terraform source:

```json
{
  "app-a": {
    "name": "app.example.com",
    "type": "A",
    "ttl": 60,
    "records": ["192.0.2.10"]
  },
  "app-aaaa": {
    "name": "app.example.com",
    "type": "AAAA",
    "ttl": 60,
    "records": ["2001:db8::10"]
  },
  "mail": {
    "name": "example.com",
    "type": "MX",
    "ttl": 300,
    "records": ["10 mail.example.com."]
  },
  "cloudfront": {
    "name": "cdn.example.com",
    "type": "A",
    "alias": {
      "name": "d1234567890.cloudfront.net",
      "zone_id": "Z2FDTNDATAQYW2",
      "evaluate_target_health": false
    }
  }
}
```

Terraform caller:

```hcl
locals {
  records = jsondecode(file("${path.module}/records/example.com.json"))
}

module "zone" {
  source = "../../modules/route53-zone"

  zone_name    = "example.com"
  private_zone = false
  records      = local.records
}
```

JSON has no comment syntax. Use descriptive map keys and document operational context in the module/caller README instead of adding comments to the JSON file.

## Supported record settings

Common fields:

| JSON field | Meaning |
|---|---|
| `name` | Relative or fully qualified record name; an apex may be `example.com` or `@`. |
| `type` | DNS record type supported by Route 53, such as `A`, `AAAA`, `CNAME`, `TXT`, `MX`, `CAA`, `SRV`, `NS`, `PTR`, or `SPF`. Do not define the zone's AWS-managed apex `NS` or `SOA` set. |
| `ttl` | TTL in seconds for non-alias records. |
| `records` | List of RDATA strings for a non-alias record. Quote JSON strings and preserve required trailing dots in DNS names. |
| `alias` | Alias target object with required `name` and `zone_id`, and optional `evaluate_target_health` (defaults to `false`). Alias records omit `ttl` and `records`. |
| `set_identifier` | Stable identifier required for each record in a routing policy. |
| `health_check_id` | Existing Route 53 health check ID, when needed. Health checks are not created by this module. |
| `allow_overwrite` | Allow Terraform to overwrite a conflicting record during create; defaults to `false`. Prefer importing existing records rather than enabling overwrite. |

Supported routing policy objects:

```json
{
  "weighted-blue": {
    "name": "service.example.com",
    "type": "CNAME",
    "ttl": 60,
    "records": ["blue.example.net."],
    "set_identifier": "blue",
    "weighted_routing_policy": { "weight": 80 }
  },
  "weighted-green": {
    "name": "service.example.com",
    "type": "CNAME",
    "ttl": 60,
    "records": ["green.example.net."],
    "set_identifier": "green",
    "weighted_routing_policy": { "weight": 20 }
  },
  "latency-ap-southeast-1": {
    "name": "latency.example.com",
    "type": "A",
    "ttl": 60,
    "records": ["192.0.2.20"],
    "set_identifier": "ap-southeast-1",
    "latency_routing_policy": { "region": "ap-southeast-1" }
  },
  "failover-primary": {
    "name": "failover.example.com",
    "type": "A",
    "ttl": 60,
    "records": ["192.0.2.30"],
    "set_identifier": "primary",
    "health_check_id": "01234567-89ab-cdef-0123-456789abcdef",
    "failover_routing_policy": { "type": "PRIMARY" }
  },
  "geo-us": {
    "name": "geo.example.com",
    "type": "A",
    "ttl": 60,
    "records": ["192.0.2.40"],
    "set_identifier": "us",
    "geolocation_routing_policy": { "country": "US" }
  },
  "geo-proximity-region": {
    "name": "proximity.example.com",
    "type": "A",
    "ttl": 60,
    "records": ["192.0.2.50"],
    "set_identifier": "ap-southeast-1",
    "geoproximity_routing_policy": {
      "aws_region": "ap-southeast-1",
      "bias": 0
    }
  },
  "cidr-default": {
    "name": "cidr.example.com",
    "type": "A",
    "ttl": 60,
    "records": ["192.0.2.60"],
    "set_identifier": "default",
    "cidr_routing_policy": {
      "collection_id": "example-cidr-collection",
      "location_name": "*"
    }
  },
  "multivalue-one": {
    "name": "multi.example.com",
    "type": "A",
    "ttl": 60,
    "records": ["192.0.2.70"],
    "multivalue_answer_routing_policy": true
  }
}
```

For geolocation, specify the applicable `continent`, `country`, and/or `subdivision` values according to Route 53's rules. Geoproximity supports optional `aws_region`, `local_zone_group`, `bias`, and `coordinates` (an object containing `latitude` and `longitude`). CIDR policies require a pre-existing CIDR collection and location. Routing policy records of the same name and type need distinct `set_identifier` values. Route 53 imposes additional record-type and routing-policy constraints; review the planned changes and AWS API errors when introducing advanced policies.

## Existing `ranul.click` zone and caller

The accompanying caller in [`aws/module-instances/route53-zone`](../../module-instances/route53-zone/) is configured to adopt public hosted zone `ranul.click` (`Z0233745IB90EWVKK2K1`) in `ap-southeast-1`. AWS scan results:

- The zone is public, has comment `Delegated by namecheap`, and has no tags or VPC associations.
- AWS-created apex `NS` and `SOA` records are left unmanaged by this caller.
- The ACM validation CNAME `_927df405c21400419c02080261c7ffd2.ranul.click` is configured in the caller's JSON record map.
- `cdn.s3-app.ranul.click` is already managed by `aws/module-instances/cloudfront` in its existing Terraform state. Do not also import or manage that record from this caller; a Route 53 record must have only one Terraform owner.
- The hosted zone's assigned name servers are already delegated at the registrar. Do not replace them during import.

The existing issued ACM certificate has another validation option for `*.s3-app.ranul.click`, but AWS's `ranul.click` hosted-zone scan did not show that second CNAME. It may be served elsewhere or no longer required; inspect DNS and certificate use before adding it. The caller intentionally includes only the record confirmed in this zone.

### Import the existing zone and validation record

The caller uses Terraform Cloud workspace `aws-dev-route53-zone-ranul-click`. Initialize from the caller directory and inspect the state before importing:

```powershell
cd aws/module-instances/route53-zone
terraform init
terraform state list
```

For a new/empty workspace, import the hosted zone and the ACM validation CNAME. Import IDs use the hosted-zone ID for the zone; record IDs use `ZONEID_RECORDNAME_TYPE` (and append `_SETIDENTIFIER` for routed sets):

```powershell
terraform import module.ranul_click.aws_route53_zone.this Z0233745IB90EWVKK2K1
terraform import 'module.ranul_click.aws_route53_record.this[\"_wildcard_ranul_click_acm_validation\"]' 'Z0233745IB90EWVKK2K1__927df405c21400419c02080261c7ffd2.ranul.click_CNAME'
terraform plan
```

The current caller enables query logging with a seven-day retention period and the default group name `/aws/route53/ranul.click/query-logs`. Check whether a query logging configuration, log group, or resource policy already exists before planning; import existing resources rather than attempting to create duplicates. The AWS identity needs permission to list query logging configurations for this preflight. Import IDs are the query configuration ID, log group name, and log group ARN for the resource-scoped policy:

```powershell
terraform import 'module.ranul_click.aws_cloudwatch_log_group.route53_query_logs[0]' '/aws/route53/ranul.click/query-logs'
terraform import 'module.ranul_click.aws_cloudwatch_log_resource_policy.route53_query_logs[0]' 'REPLACE_WITH_LOG_GROUP_ARN'
terraform import 'module.ranul_click.aws_route53_query_log.this[0]' 'REPLACE_WITH_QUERY_LOG_CONFIGURATION_ID'
```

Only run imports for resources confirmed to exist. The query configuration ID can be looked up with `aws route53 list-query-logging-configs --hosted-zone-id Z0233745IB90EWVKK2K1`.

For PowerShell versions that strip the inner quotes from a `for_each` address, escape the quotes with backticks:

```powershell
terraform import "module.ranul_click.aws_route53_record.this[`"_wildcard_ranul_click_acm_validation`"]" "Z0233745IB90EWVKK2K1__927df405c21400419c02080261c7ffd2.ranul.click_CNAME"
```

Do not import the CDN CNAME here: it is already tracked by the CloudFront caller. Do not import NS/SOA unless you intentionally want to manage those AWS-generated records. Import only associates remote resources with state; it does not change DNS. Review the plan before applying and make no changes that alter delegation or delete records unexpectedly.

### Configuration and outputs

Caller record data is stored in [`records/ranul.click.json`](../../module-instances/route53-zone/records/ranul.click.json). Add or edit records as map entries; the key is the Terraform resource key, and the map value uses the schema above. For a live record already present in Route 53, add the correct JSON entry, import its corresponding `module.ranul_click.aws_route53_record.this["<key>"]`, and review `terraform plan` before any apply.

The module outputs the hosted-zone ID and name, public/private status, authoritative name servers, VPC associations, managed record FQDNs, full managed record resources, and query logging status, log group name/ARN, and configuration ID. The caller forwards the zone identity, name servers, record FQDN map, and query logging status, destination name/ARN, and configuration ID.

## Source layout

- `main.tf` creates the hosted zone and its initial private-zone VPC associations.
- `records.tf` manages standard, alias, and routed record sets.
- `logging.tf` configures optional public DNS query logging and its CloudWatch Logs destination.
- `locals.tf` derives the default query log group name.
- `variables.tf` defines and validates the module inputs.
- `outputs.tf` exports zone and record details.
- `versions.tf` declares Terraform and AWS provider requirements.
