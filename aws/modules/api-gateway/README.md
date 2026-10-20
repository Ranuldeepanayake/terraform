# API Gateway module

This module creates an API Gateway HTTP API, its Lambda integrations and routes,
and one or more stages. Routes and integrations belong to the API and are shared
by all its stages. Stage settings control deployments and stage behavior; they
do not select a different set of Lambda functions. For different backends,
create a separate module instance with its own `lambda_functions` and `routes`.

## Stage configuration

Stages are keyed by their API Gateway stage names. If `stages` is omitted, the
module creates a `$default` stage. The default stage uses the API endpoint
without a stage-name suffix. Named stages have their name appended to the
endpoint, for example `https://<api-id>.execute-api.<region>.amazonaws.com/dev`.
The `api_gateway_stage_urls` output returns these URLs by stage name.

Each stage can independently configure:

- `description`, `stage_variables`, and `tags`
- Access logging: `logging.enabled`, `logging.log_group_name`,
  `logging.retention_in_days`, and `logging.format`
- Default throttling: `throttling.enabled`, `throttling.rate_limit`, and
  `throttling.burst_limit`
- Metrics and execution logging: `detailed_metrics_enabled`, `logging_level`,
  and `data_trace_enabled`
- Optional per-route overrides in `route_settings`, keyed by API Gateway route
  key (for example, `"GET /health-check"`)
- Custom-domain path mappings with `custom_domain_mapping_key`

Access logs are written to a separate CloudWatch log group per stage. If a
stage doesn't specify its own logging or throttling values, legacy module-level
`logging`, `throttling`, and `detailed_metrics_enabled` settings are used as
defaults. Without those settings, logging is enabled with a generated log group,
throttling is disabled, and detailed metrics are disabled.

```hcl
stages = {
  "$default" = {
    auto_deploy = true
    logging = {
      enabled           = true
      log_group_name    = "/aws/apigateway/example/default"
      retention_in_days = 14
    }
    throttling = {
      enabled     = true
      rate_limit  = 100
      burst_limit = 200
    }
    detailed_metrics_enabled = true
  }

  dev = {
    description = "Development"
    auto_deploy = true
    logging = {
      enabled           = true
      log_group_name    = "/aws/apigateway/example/dev"
      retention_in_days = 7
    }
    throttling = {
      enabled     = true
      rate_limit  = 25
      burst_limit = 50
    }
    detailed_metrics_enabled = true
    route_settings = {
      "GET /health-check" = {
        throttling_rate_limit  = 10
        throttling_burst_limit = 20
      }
    }
  }
}
```

You can omit `$default` and configure only named stages, or explicitly configure
`"$default"` as above. To keep the legacy single default stage, omit `stages`
entirely.

## Manual deployments

`auto_deploy` defaults to `true`. For a stage with `auto_deploy = false`, set a
non-empty `deployment_trigger`. The module creates a deployment snapshot for
that stage and assigns it to the stage. To publish an updated API configuration
to that stage, change its trigger (for example, from `"prod-v1"` to
`"prod-v2"`) and apply Terraform. The changed trigger replaces the deployment
and updates the stage to the new snapshot. Other manual stages are unaffected
unless their own triggers change.

Terraform cannot infer that a manual stage should publish every API change;
leave its trigger unchanged to keep the currently deployed snapshot. Ensure the
configured routes and integrations are in the plan before changing the trigger.
Automatic stages continue to deploy API changes automatically.

## Custom domains

Set `custom_domain` to create the custom domain, certificate, and DNS validation
resources. Configure a mapping key on each stage you want exposed on that
domain. A mapping key is a path prefix without a leading slash; for example,
`"dev"` and `"prod"` produce `https://api.example.com/dev` and
`https://api.example.com/prod`. Use an empty string as the key for a root
mapping; it can be combined with named path mappings.

```hcl
custom_domain = "api.example.com"

stages = {
  dev = {
    auto_deploy               = true
    custom_domain_mapping_key = "dev"
  }
  prod = {
    auto_deploy               = false
    deployment_trigger        = "prod-v1"
    custom_domain_mapping_key = "prod"
  }
  "$default" = {
    auto_deploy               = true
    custom_domain_mapping_key = ""
  }
}
```

The `api_gateway_custom_domain_urls` output contains custom-domain URLs keyed
by stage. When no stage specifies `custom_domain_mapping_key`, the module keeps
the legacy single root mapping selected by `custom_domain_stage`.
