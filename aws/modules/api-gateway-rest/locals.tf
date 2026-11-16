locals {
  # Expand each route path into all ancestor path nodes so the full resource tree can be built.
  # "/api/v1/users" produces ["/api", "/api/v1", "/api/v1/users"].
  all_path_nodes = toset(flatten([
    for path in [for r in var.routes : r.path] : [
      for i in range(1, length(split("/", trimprefix(path, "/"))) + 1) :
      "/${join("/", slice(split("/", trimprefix(path, "/")), 0, i))}"
    ]
  ]))

  path_node_map = {
    for node in local.all_path_nodes : node => {
      segment = element(
        split("/", trimprefix(node, "/")),
        length(split("/", trimprefix(node, "/"))) - 1
      )
      parent_path = length(split("/", trimprefix(node, "/"))) == 1 ? "/" : (
        "/${join("/", slice(split("/", trimprefix(node, "/")), 0, length(split("/", trimprefix(node, "/"))) - 1))}"
      )
    }
  }

  # Path nodes split by depth so each level can be a separate resource without self-reference.
  path_nodes_l1 = { for k, v in local.path_node_map : k => v if length(split("/", trimprefix(k, "/"))) == 1 }
  path_nodes_l2 = { for k, v in local.path_node_map : k => v if length(split("/", trimprefix(k, "/"))) == 2 }
  path_nodes_l3 = { for k, v in local.path_node_map : k => v if length(split("/", trimprefix(k, "/"))) == 3 }
  path_nodes_l4 = { for k, v in local.path_node_map : k => v if length(split("/", trimprefix(k, "/"))) == 4 }

  # Merged resource ID map keyed by path — used by methods, integrations, and CORS resources.
  all_resource_ids = merge(
    { for k, v in aws_api_gateway_resource.l1 : k => v.id },
    { for k, v in aws_api_gateway_resource.l2 : k => v.id },
    { for k, v in aws_api_gateway_resource.l3 : k => v.id },
    { for k, v in aws_api_gateway_resource.l4 : k => v.id },
  )

  stage_logging = {
    for name, stage in var.stages : name => {
      enabled = coalesce(try(stage.logging.enabled, null), true)
      log_group_name = coalesce(
        try(stage.logging.log_group_name, null),
        "/aws/apigateway/${var.api_gateway_name}/${name}"
      )
      retention_in_days = coalesce(try(stage.logging.retention_in_days, null), 30)
      format = coalesce(try(stage.logging.format, null), jsonencode({
        requestId        = "$context.requestId"
        sourceIp         = "$context.identity.sourceIp"
        requestTime      = "$context.requestTime"
        httpMethod       = "$context.httpMethod"
        resourcePath     = "$context.resourcePath"
        status           = "$context.status"
        protocol         = "$context.protocol"
        responseLength   = "$context.responseLength"
        integrationError = "$context.integrationErrorMessage"
      }))
    }
  }

  custom_domain_mappings_by_stage = {
    for name, stage in var.stages : name => {
      stage_name  = name
      mapping_key = stage.custom_domain_mapping_key
    } if var.custom_domain != null && stage.custom_domain_mapping_key != null
  }

  # True when at least one route requires an API key — controls whether API keys are created.
  api_key_routes_exist = anytrue([for r in var.routes : coalesce(r.api_key_required, false)])

  # Maps route logical name to the method_path format used by aws_api_gateway_method_settings:
  # "health-check" -> "health-check/GET"
  route_method_paths = {
    for key, route in var.routes :
    key => "${trimprefix(route.path, "/")}/${upper(route.method)}"
  }
}
