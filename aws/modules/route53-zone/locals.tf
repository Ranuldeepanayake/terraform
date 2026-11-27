locals {
  query_log_group_name = coalesce(
    var.query_log_group_name,
    "/aws/route53/${var.zone_name}/query-logs"
  )
}
