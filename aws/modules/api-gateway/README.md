# API Gateway module

This module creates an API Gateway HTTP API, its Lambda integrations and routes,
and one or more stages. Routes and integrations belong to the API and are shared
by every stage. Stages provide independent deployment URLs and stage-level
settings; they do not select different Lambda functions. Use separate module
instances when environments need different backends.

## Calling the module

### Default stage only

For the usual single default stage, **omit the `stages` argument entirely**.
The module's default value creates one `$default` stage with automatic
deployment. Do not set `stages = {}`: the module requires at least one stage.
The `$default` URL is the API endpoint itself and has no stage-name suffix.

```hcl
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_gateway_name = "example-api"
  lambda_functions = {
    health = { arn = aws_lambda_function.health.arn }
  }
  routes = {
    health = {
      method  = "GET"
      path    = "/health"
      lambda  = "health"
      default = true
    }
  }

  # Do not set stages for a default-only API.
  # Do not set custom_domain_mapping_key unless custom_domain is configured.
}
```

If the default stage needs custom settings, set `stages` to a map containing
only the special key `"$default"`; see the mixed-stage example below and remove
the named stage.

### One named stage and the default stage

To have both the default endpoint and a named endpoint, explicitly include
both `"$default"` and the named stage as keys in `stages`. The key `"$default"`
is required to create that stage when you provide a `stages` map; it is not
created implicitly alongside other configured stages.

```hcl
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_gateway_name = "example-api"
  lambda_functions = {
    health = { arn = aws_lambda_function.health.arn }
  }
  routes = {
    health = {
      method  = "GET"
      path    = "/health"
      lambda  = "health"
      default = true
    }
  }

  stages = {
    "$default" = {
      auto_deploy = true
      # Add settings here only if the default stage needs overrides.
    }
    dev = {
      auto_deploy = true
      # Add settings here only if the dev stage needs overrides.
    }
  }
}
```

Here `$default` uses the API endpoint without a stage-name suffix; `dev` uses
the endpoint followed by `/dev`. The `api_gateway_stage_urls` output returns
both URLs keyed by `"$default"` and `"dev"`.

For **one named stage only**, set `stages` to just that named key, such as
`stages = { dev = { auto_deploy = true } }`. Do not include `"$default"` in
that case; no default stage will be created.

## Per-stage settings

Each stage can configure its deployment, logging, throttling, metrics, stage
variables, tags, and custom-domain path mapping independently:

- `description`, `stage_variables`, and `tags`
- Access logging: `logging.enabled`, `logging.log_group_name`,
  `logging.retention_in_days`, and `logging.format`
- Default throttling: `throttling.enabled`, `throttling.rate_limit`, and
  `throttling.burst_limit`
- Execution logging and metrics: `logging_level`, `data_trace_enabled`, and
  `detailed_metrics_enabled`
- Route-specific overrides in `route_settings`, keyed by API Gateway route key
  (for example, `"GET /health"`)
- `auto_deploy` and, for manual deployment, `deployment_trigger`
- Custom-domain path prefix with `custom_domain_mapping_key`

Access logging is enabled by default and writes to a separate CloudWatch log
group per stage. The default log-group name is
`/aws/apigateway/<api-name>` for `$default` and
`/aws/apigateway/<api-name>/<stage-name>` for named stages. Log retention
defaults to 30 days. Throttling and detailed metrics are disabled unless
enabled for a stage. When throttling is enabled, rate and burst limits default
to 100 and 200 respectively.

```hcl
stages = {
  dev = {
    auto_deploy              = true
    detailed_metrics_enabled = true
    logging_level            = "INFO"
    logging = {
      enabled           = true
      log_group_name    = "/aws/apigateway/example-api/dev"
      retention_in_days = 7
    }
    throttling = {
      enabled     = true
      rate_limit  = 25
      burst_limit = 50
    }
    route_settings = {
      "GET /health" = {
        throttling_rate_limit  = 10
        throttling_burst_limit = 20
      }
    }
  }
}
```

## Manual deployments

Stages use automatic deployments by default. For `auto_deploy = false`, provide
a non-empty `deployment_trigger`. The module creates a deployment snapshot and
assigns it to that stage. Change the trigger (for example, from `"prod-v1"` to
`"prod-v2"`) and apply Terraform to publish a new snapshot to the stage.
Changing routes or integrations without changing the trigger does not publish
those changes to a manual stage. Other stages are deployed according to their
own `auto_deploy` settings and triggers.

## Custom domains

Set `custom_domain` to create the custom domain, certificate, and DNS
validation resources. A stage is mapped to the domain only when it sets
`custom_domain_mapping_key`. Mapping keys must be unique and cannot begin with
`/`. Use an empty string for a root mapping. For example:

```hcl
custom_domain = "api.example.com"

stages = {
  "$default" = {
    auto_deploy               = true
    custom_domain_mapping_key = ""
  }
  dev = {
    auto_deploy               = true
    custom_domain_mapping_key = "dev"
  }
}
```

The root mapping is `https://api.example.com`; the named mapping is
`https://api.example.com/dev`. The `api_gateway_custom_domain_urls` output
returns URLs for configured mappings, keyed by stage name. If a stage has no
mapping key, it is not exposed on the custom domain. If the domain should map
only to the named stage, omit the `$default` mapping key.
