# api-gateway-rest

Terraform module that creates an AWS REST API (API Gateway v1) backed by Lambda proxy integrations. Supports per-stage throttling, CORS preflight handling, usage plans with quotas, API key management, and a TLS-terminated custom domain.

## Features

- REST API (`aws_api_gateway_rest_api`) with automatic hierarchical path resource tree
- Lambda proxy (`AWS_PROXY`) integrations per route
- Per-stage throttling and execution logging via `aws_api_gateway_method_settings`
- Optional CORS preflight via OPTIONS methods with MOCK integrations on every resource path
- Usage plans with per-plan throttle and quota limits
- API keys created automatically per usage plan when any route requires key authorization
- Per-route `api_key_required` toggle, independent of the authorization type
- TLS custom domain via ACM + Route 53 DNS validation

## Usage

### Minimal example

```hcl
module "api_gateway" {
  source = "../../modules/api-gateway-rest"

  api_gateway_name   = "my-api"
  deployment_trigger = "v1"

  lambda_functions = {
    my-function = { arn = "arn:aws:lambda:ap-southeast-1:123456789012:function:my-function" }
  }

  routes = {
    hello = {
      method = "GET"
      path   = "/hello"
      lambda = "my-function"
    }
  }

  route53_hosted_zone_name = "example.com"
}
```

### With usage plans and API key authorization

```hcl
routes = {
  public = {
    method           = "GET"
    path             = "/public"
    lambda           = "my-function"
    api_key_required = false
  }
  protected = {
    method           = "POST"
    path             = "/data"
    lambda           = "my-function"
    api_key_required = true   # requires x-api-key header
  }
}

usage_plans = {
  standard = {
    description = "Standard tier"
    stages      = ["prod"]
    throttle = {
      rate_limit  = 100
      burst_limit = 200
    }
    quota = {
      limit  = 50000
      period = "MONTH"
    }
  }
  premium = {
    description = "Premium tier"
    stages      = ["prod"]
    throttle = {
      rate_limit  = 1000
      burst_limit = 2000
    }
  }
}
```

Because `protected` has `api_key_required = true`, the module creates one `aws_api_gateway_api_key` per usage plan (`standard-key`, `premium-key`) and links them. Retrieve values via the `api_gateway_api_key_values` output (sensitive).

Usage plans without API key routes still apply throttle and quota to all callers of the associated stages.

### With CORS

```hcl
cors_configuration = {
  allow_headers = ["authorization", "content-type", "x-api-key"]
  allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
  allow_origins = ["*"]
}
```

An OPTIONS method with a MOCK integration is added to every resource path. This handles browser preflight requests. **Lambda must return `Access-Control-Allow-Origin` and related headers in actual (non-OPTIONS) responses** — API Gateway cannot inject them into `AWS_PROXY` passthrough responses.

`allow_origins` accepts a list but the `Access-Control-Allow-Origin` response header only supports a single value or `*`. Provide exactly one origin or `"*"`.

### With a custom domain

```hcl
custom_domain               = "api.example.com"
endpoint_type_custom_domain = "REGIONAL"
security_policy             = "TLS_1_2"
certificate_validation_method = "DNS"

certificate_subject_alternative_names = ["www.api.example.com"]

route53_hosted_zone_name = "example.com"
route53_private_zone     = false

stages = {
  prod = {
    custom_domain_mapping_key = ""    # maps https://api.example.com/ → prod stage
  }
  dev = {
    custom_domain_mapping_key = "dev" # maps https://api.example.com/dev → dev stage
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `api_gateway_name` | Name of the REST API | `string` | — | yes |
| `deployment_trigger` | Change to force a new deployment across all stages | `string` | — | yes |
| `lambda_functions` | Lambda functions keyed by logical name `{ arn }` | `map(object)` | — | yes |
| `routes` | Routes keyed by logical name. See [Routes](#routes). | `map(object)` | — | yes |
| `description` | Description of the REST API | `string` | `null` | no |
| `endpoint_type` | API endpoint type: `REGIONAL`, `EDGE`, or `PRIVATE` | `string` | `"REGIONAL"` | no |
| `integration_type` | Lambda integration type | `string` | `"AWS_PROXY"` | no |
| `integration_method` | HTTP method used to call the Lambda | `string` | `"POST"` | no |
| `integration_timeout_milliseconds` | Max Lambda wait time in ms (1–29000) | `number` | `29000` | no |
| `cors_configuration` | CORS config for preflight. See [CORS](#cors). | `object` | `null` | no |
| `stages` | Stages keyed by name. See [Stages](#stages). | `map(object)` | `{ prod = {} }` | no |
| `usage_plans` | Usage plans keyed by logical name. See [Usage plans](#usage-plans). | `map(object)` | `{}` | no |
| `custom_domain` | Custom domain name | `string` | `null` | no |
| `endpoint_type_custom_domain` | Custom domain endpoint type: `REGIONAL` or `EDGE` | `string` | `"REGIONAL"` | no |
| `security_policy` | TLS policy for the custom domain | `string` | `"TLS_1_2"` | no |
| `certificate_validation_method` | ACM validation: `DNS` or `EMAIL` | `string` | `"DNS"` | no |
| `certificate_subject_alternative_names` | SANs for the ACM certificate | `list(string)` | `[]` | no |
| `route53_hosted_zone_name` | Route 53 zone name for DNS validation. Required when `custom_domain` is set and `certificate_validation_method = "DNS"`. | `string` | `null` | no |
| `route53_private_zone` | Whether the Route 53 zone is private | `bool` | `false` | no |
| `tags` | Tags applied to all taggable resources | `map(string)` | `{}` | no |

### Default / catch-all route

REST API has no `$default` route equivalent. The closest is a root-level `{proxy+}` resource with `ANY` method — a greedy path variable that matches any path and method not handled by a more specific route. This module does not currently implement it. If a request arrives at a path with no matching route, API Gateway returns HTTP **403 Forbidden**.

### Routes

```hcl
routes = {
  <logical-name> = {
    method           = string        # HTTP method: GET, POST, PUT, PATCH, DELETE
    path             = string        # Resource path, e.g. "/users" or "/api/v1/items"
    lambda           = string        # Key in var.lambda_functions
    authorization    = string        # NONE | AWS_IAM | CUSTOM | COGNITO_USER_POOLS. Default: "NONE"
    api_key_required = bool          # Whether callers must include x-api-key. Default: false
  }
}
```

`authorization` and `api_key_required` are independent controls evaluated separately by API Gateway.

**`authorization`** — verifies the caller's *identity* before invoking Lambda:

| Value | What it checks |
|---|---|
| `"NONE"` | No identity check |
| `"AWS_IAM"` | Valid AWS SigV4 signature (IAM user or role) |
| `"COGNITO_USER_POOLS"` | Valid JWT from a Cognito user pool |
| `"CUSTOM"` | A Lambda authorizer you provide |

**`api_key_required`** — verifies the caller holds a *provisioned key* associated with a usage plan for the stage. Does not verify identity.

| Value | Effect |
|---|---|
| `false` | No key needed |
| `true` | Must include a valid `x-api-key` header tied to an active usage plan |

They can be combined freely:

| `authorization` | `api_key_required` | Who can call |
|---|---|---|
| `"NONE"` | `false` | Anyone |
| `"NONE"` | `true` | Anyone with a valid key |
| `"COGNITO_USER_POOLS"` | `false` | Any authenticated Cognito user |
| `"COGNITO_USER_POOLS"` | `true` | Authenticated Cognito user **and** valid key |
| `"AWS_IAM"` | `true` | Valid IAM principal **and** valid key |

API keys are intended for client provisioning and rate-limit tiering, not as a security boundary. AWS recommends not treating them as secrets for authentication purposes — use `authorization` for that.

### Stages

```hcl
stages = {
  <stage-name> = {
    description               = string
    stage_variables           = map(string)
    tags                      = map(string)
    detailed_metrics_enabled  = bool
    logging_level             = string        # OFF | ERROR | INFO
    data_trace_enabled        = bool
    xray_tracing_enabled      = bool
    custom_domain_mapping_key = string        # "" for root, "dev" for /dev path
    logging = {
      enabled           = bool
      log_group_name    = string
      retention_in_days = number
    }
    throttling = {
      enabled     = bool
      rate_limit  = number   # requests/sec
      burst_limit = number   # concurrent requests
    }
    route_settings = {
      <route-logical-name> = {
        throttling_rate_limit    = number
        throttling_burst_limit   = number
        detailed_metrics_enabled = bool
        logging_level            = string
        data_trace_enabled       = bool
      }
    }
  }
}
```

`route_settings` keys are route logical names (the map keys from `var.routes`), not route keys. The module converts them to the `resource_path/HTTP_METHOD` format required by `aws_api_gateway_method_settings`.

### Usage plans

```hcl
usage_plans = {
  <plan-name> = {
    description = string
    stages      = list(string)   # must match keys in var.stages
    throttle = {
      rate_limit  = number
      burst_limit = number
    }
    quota = {
      limit  = number
      period = string   # DAY | WEEK | MONTH
    }
  }
}
```

## Outputs

| Name | Description |
|---|---|
| `api_gateway_id` | REST API ID |
| `api_gateway_execution_arn` | REST API execution ARN |
| `api_gateway_stage_urls` | Invoke URLs keyed by stage name |
| `api_gateway_custom_domain_urls` | Custom-domain URLs keyed by stage name |
| `api_gateway_routes` | Configured routes with all resolved fields |
| `api_gateway_api_key_ids` | API key IDs keyed by usage plan name |
| `api_gateway_api_key_values` | API key values keyed by usage plan name (**sensitive**) |
| `api_gateway_usage_plan_ids` | Usage plan IDs keyed by plan name |

## Notes

### Stage URLs

REST API stage names are always embedded in the raw invoke URL:

```
https://{api-id}.execute-api.{region}.amazonaws.com/{stage-name}/
```

There is no `$default` stage equivalent in REST API. Via a custom domain with an empty base path (`custom_domain_mapping_key = ""`), the stage name is hidden from the URL.

#### Custom domain mapping

Set `custom_domain_mapping_key` on each stage to control how it appears under the custom domain. Stages without this field set are not mapped to the custom domain at all.

| `custom_domain_mapping_key` | Custom domain URL |
|---|---|
| `""` (empty string) | `https://api.example.com/` — root, no path prefix |
| `"dev"` | `https://api.example.com/dev` |
| `null` / omitted | Stage not mapped; no custom domain URL |

Example with two stages:

```hcl
stages = {
  prod = {
    custom_domain_mapping_key = ""     # https://api.example.com/
  }
  dev = {
    custom_domain_mapping_key = "dev"  # https://api.example.com/dev
  }
}
```

After apply, `terraform output api_gateway_custom_domain_urls` returns:

```json
{
  "prod": "https://api.example.com",
  "dev":  "https://api.example.com/dev"
}
```

Only stages with `custom_domain_mapping_key` set appear in this output. The raw execute-api URLs for all stages are always available in `api_gateway_stage_urls` regardless of domain mapping.

### Deployment trigger

All stages share one deployment snapshot. REST API does not have an `auto_deploy` equivalent — Terraform will create new routes and integrations, but they are **not live** until a new deployment captures them. Changes are invisible to callers until you publish a deployment.

To publish, change `deployment_trigger` to a new value and run `terraform apply`:

```hcl
deployment_trigger = "v2"  # increment whenever you want to publish
```

The deployment uses `create_before_destroy`, so the new snapshot goes live before the old one is destroyed — no downtime.

**If you forget to update the trigger**, the infrastructure changes apply in AWS but stages continue serving the previous snapshot. The API behaves as if your changes do not exist.

Common strategies for the trigger value:

| Strategy | Example | Trade-off |
|---|---|---|
| Semantic version | `"v1"`, `"v2"` | Intentional and clean — requires a manual bump |
| Date string | `"2025-10-30"` | Easy to reason about, clashes if applied twice in a day |
| Change description | `"add-user-route"` | Self-documenting, verbose over time |

### CloudWatch logs

The module creates an IAM role and sets it as the account-level API Gateway CloudWatch role (`aws_api_gateway_account`). This resource is a singleton per AWS account/region. If you deploy multiple instances of this module in the same account, set `manage_cloudwatch_account = false` on all but one instance to avoid state conflicts on destroy.

### CORS

The module adds OPTIONS methods with MOCK integrations to handle browser preflight requests. The MOCK integration statically returns the configured CORS headers. **Lambda functions are responsible for returning CORS headers on all non-OPTIONS responses** — API Gateway cannot modify `AWS_PROXY` passthrough responses.

`allow_origins` should contain a single value or `*`. The `Access-Control-Allow-Origin` response header does not support comma-separated multiple origins.

### Route 53 records

When `custom_domain` and `route53_hosted_zone_name` are both set, the module creates two sets of Route 53 records:

| Record | Type | Purpose |
|---|---|---|
| `_<hash>.<custom_domain>` | CNAME | ACM certificate DNS validation (one per domain + SAN) |
| `<custom_domain>` | A (ALIAS) | Routes the custom domain to the API Gateway regional/CloudFront endpoint |

The ALIAS record points to the API Gateway domain endpoint (`d-xxxxx.execute-api.<region>.amazonaws.com` for REGIONAL, or a CloudFront hostname for EDGE). Without it the domain resolves to NXDOMAIN even though the certificate is issued and the API Gateway domain status is AVAILABLE.

If you previously had a CNAME record on the same name (e.g., from a different stack), delete it before applying — Route 53 does not allow a CNAME and an A record to coexist on the same name.

### EDGE endpoint

The `EDGE` endpoint type for custom domains requires the ACM certificate to be in `us-east-1`. This module provisions the certificate in the provider's configured region. If your provider is not `us-east-1`, use `REGIONAL` for the custom domain or configure a separate provider alias in us-east-1 outside this module.

### API keys

When at least one route has `api_key_required = true`, the module creates one `aws_api_gateway_api_key` per usage plan and associates it via `aws_api_gateway_usage_plan_key`. Callers must include the key in the `x-api-key` request header.

API key values are available in the `api_gateway_api_key_values` output (marked sensitive). Retrieve with:

```
terraform output -json api_gateway_api_key_values
```

Pass the key in the `x-api-key` header on every request to a protected route:

```bash
curl -X POST https://api.example.com/data \
  -H "x-api-key: your-api-key-value" \
  -H "content-type: application/json" \
  -d '{"key": "value"}'
```

Routes with `api_key_required = false` ignore the header. Routes with `api_key_required = true` return HTTP **403 Forbidden** if the header is missing or the key is not associated with a usage plan for that stage.

### Throttling and quotas

Throttling exists at three independent levels. The most restrictive limit in effect for a given request wins.

| Level | Configured via | Scope | Applies to |
|---|---|---|---|
| Stage default | `stages.<name>.throttling` | All methods in a stage | **All callers combined** — shared aggregate bucket |
| Per-route override | `stages.<name>.route_settings.<route>` | One method in one stage | **All callers combined** — shared aggregate bucket |
| Usage plan | `usage_plans.<name>.throttle` | API key across its associated stages | **Per API key** — each key has its own independent bucket |

Stage and route throttling is not per-client — it controls the total traffic a stage or route can sustain regardless of who is calling. A spike from one client consumes capacity for all others.

Usage plan throttling and quotas are scoped to an individual API key:

- **Throttle** (`rate_limit`, `burst_limit`): enforced continuously; a throttled request gets HTTP 429 immediately.
- **Quota** (`limit`, `period`): a fixed request count per calendar window (`DAY`, `WEEK`, `MONTH`); once exhausted the key receives HTTP 403 until the period resets.

Callers without an API key (routes with `api_key_required = false`) are subject only to stage and route-level throttling. They are never subject to quota limits.

#### Stage throttle vs usage plan throttle

Stage and usage plan throttle are two **independent enforcement points**. A request passes through both in sequence; either one can reject it with HTTP 429.

```
Request arrives
      │
      ▼
[Stage bucket] ── exhausted ──► 429  (affects all callers on this stage)
      │
      │  (only when api_key_required = true)
      ▼
[Usage plan bucket for this key] ── exhausted ──► 429  (affects only this key)
      │
      ▼
   Lambda
```

The effective ceiling for a keyed caller is `min(stage_limit, usage_plan_limit)`. However, because the stage bucket is shared, keyed callers consuming stage capacity reduce the available headroom for every other caller — including unkeyed ones on `api_key_required = false` routes.

**Example** — stage limit 200 req/s, standard key at 50 req/s, premium key at 150 req/s:

| Caller | Effective limit | Reason |
|---|---|---|
| Standard key alone | 50 req/s | Usage plan wins |
| Premium key alone | 150 req/s | Usage plan wins |
| Both keys at full speed | ≤ 200 req/s combined | Stage bucket exhausted, both throttled |
| Unkeyed caller while both keys fire | Less than stage limit | Stage bucket already drained by keyed traffic |

Per-route `route_settings` overrides replace the stage default for that specific route — they do not act as a ceiling. A route can be configured higher or lower than the stage default; the override takes full effect regardless of direction.
