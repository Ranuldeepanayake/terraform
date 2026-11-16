resource "aws_api_gateway_usage_plan" "this" {
  for_each = var.usage_plans

  name        = "${var.api_gateway_name}-${each.key}"
  description = each.value.description

  dynamic "api_stages" {
    for_each = each.value.stages
    content {
      api_id = aws_api_gateway_rest_api.this.id
      stage  = aws_api_gateway_stage.this[api_stages.value].stage_name
    }
  }

  dynamic "throttle_settings" {
    for_each = each.value.throttle != null ? [each.value.throttle] : []
    content {
      burst_limit = coalesce(throttle_settings.value.burst_limit, 0)
      rate_limit  = coalesce(throttle_settings.value.rate_limit, 0)
    }
  }

  dynamic "quota_settings" {
    for_each = each.value.quota != null ? [each.value.quota] : []
    content {
      limit  = quota_settings.value.limit
      period = quota_settings.value.period
    }
  }

  tags = var.tags
}

# API keys are provisioned only when at least one route has api_key_required = true. Usage plans without
# keyed routes still enforce throttle and quota against unauthenticated callers.
# One key per plan is the simplest model; callers needing multiple keys per plan should manage additional
# aws_api_gateway_api_key resources outside this module.
resource "aws_api_gateway_api_key" "this" {
  for_each = local.api_key_routes_exist ? var.usage_plans : {}

  name    = "${var.api_gateway_name}-${each.key}-key"
  enabled = true
  tags    = var.tags
}

resource "aws_api_gateway_usage_plan_key" "this" {
  for_each = local.api_key_routes_exist ? var.usage_plans : {}

  key_id        = aws_api_gateway_api_key.this[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this[each.key].id
}
