# Manage simple, alias, and policy-routed record sets within this hosted zone.
resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id                          = aws_route53_zone.this.zone_id
  name                             = each.value.name
  type                             = each.value.type
  ttl                              = try(each.value.ttl, null)
  records                          = try(each.value.records, null)
  set_identifier                   = try(each.value.set_identifier, null)
  health_check_id                  = try(each.value.health_check_id, null)
  allow_overwrite                  = try(each.value.allow_overwrite, false)
  multivalue_answer_routing_policy = try(each.value.multivalue_answer_routing_policy, null)

  dynamic "alias" {
    for_each = try(each.value.alias, null) == null ? [] : [each.value.alias]
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = try(alias.value.evaluate_target_health, false)
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = try(each.value.weighted_routing_policy, null) == null ? [] : [each.value.weighted_routing_policy]
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  dynamic "latency_routing_policy" {
    for_each = try(each.value.latency_routing_policy, null) == null ? [] : [each.value.latency_routing_policy]
    content {
      region = latency_routing_policy.value.region
    }
  }

  dynamic "failover_routing_policy" {
    for_each = try(each.value.failover_routing_policy, null) == null ? [] : [each.value.failover_routing_policy]
    content {
      type = failover_routing_policy.value.type
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = try(each.value.geolocation_routing_policy, null) == null ? [] : [each.value.geolocation_routing_policy]
    content {
      continent   = try(geolocation_routing_policy.value.continent, null)
      country     = try(geolocation_routing_policy.value.country, null)
      subdivision = try(geolocation_routing_policy.value.subdivision, null)
    }
  }

  dynamic "geoproximity_routing_policy" {
    for_each = try(each.value.geoproximity_routing_policy, null) == null ? [] : [each.value.geoproximity_routing_policy]
    content {
      aws_region       = try(geoproximity_routing_policy.value.aws_region, null)
      bias             = try(geoproximity_routing_policy.value.bias, null)
      local_zone_group = try(geoproximity_routing_policy.value.local_zone_group, null)

      dynamic "coordinates" {
        for_each = try(geoproximity_routing_policy.value.coordinates, null) == null ? [] : [geoproximity_routing_policy.value.coordinates]
        content {
          latitude  = coordinates.value.latitude
          longitude = coordinates.value.longitude
        }
      }
    }
  }

  dynamic "cidr_routing_policy" {
    for_each = try(each.value.cidr_routing_policy, null) == null ? [] : [each.value.cidr_routing_policy]
    content {
      collection_id = cidr_routing_policy.value.collection_id
      location_name = cidr_routing_policy.value.location_name
    }
  }

  lifecycle {
    precondition {
      condition = try(
        trimspace(each.value.name) != "" &&
        trimspace(each.value.type) != "" &&
        (try(each.value.alias, null) == null) != (length(try(each.value.records, [])) == 0) &&
        (
          try(each.value.alias, null) != null ?
          try(each.value.ttl, null) == null && length(try(each.value.records, [])) == 0 :
          try(each.value.ttl, null) != null
        ) &&
        (
          length([
            for policy_name in [
              "weighted_routing_policy",
              "latency_routing_policy",
              "failover_routing_policy",
              "geolocation_routing_policy",
              "geoproximity_routing_policy",
              "cidr_routing_policy"
            ] : policy_name if try(each.value[policy_name], null) != null
          ]) +
          (try(each.value.multivalue_answer_routing_policy, false) ? 1 : 0)
        ) <= 1 &&
        (
          length([
            for policy_name in [
              "weighted_routing_policy",
              "latency_routing_policy",
              "failover_routing_policy",
              "geolocation_routing_policy",
              "geoproximity_routing_policy",
              "cidr_routing_policy"
            ] : policy_name if try(each.value[policy_name], null) != null
          ]) +
          (try(each.value.multivalue_answer_routing_policy, false) ? 1 : 0) == 0 ||
          try(trimspace(each.value.set_identifier), "") != ""
        ),
        false
      )
      error_message = "Each record must set either alias or non-empty records (not both); non-alias records need a TTL. Choose at most one routing policy and provide set_identifier when using one."
    }
  }
}
