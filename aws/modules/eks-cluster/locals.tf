locals {
  # Extract OIDC provider URL for use in IRSA trust policies.
  # Removes https:// prefix to match AWS OIDC provider naming convention.
  oidc_provider_url = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")

  # External DNS IAM policy ARN for the service account. 
  # If not provided, defaults to a policy named in var.external_dns_policy_name.
  external_dns_policy_arn = coalesce(var.external_dns_policy_arn, "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.external_dns_policy_name}")

  # Reuse a caller-owned SNS topic when supplied; otherwise reference the
  # module-created topic only while monitoring is enabled.
  alarm_topic_arn     = var.alarm_sns_topic_arn != null ? var.alarm_sns_topic_arn : try(aws_sns_topic.alarm_email[0].arn, null)
  alarm_topic_actions = local.alarm_topic_arn == null ? [] : [local.alarm_topic_arn]
  effective_alarm_actions = distinct(concat(
    var.alarm_actions,
    local.alarm_topic_actions,
  ))

  # Metric definitions use the dimensions emitted by AWS/EKS and enhanced
  # Container Insights. ClusterName-only node series represent cluster rollups.
  builtin_alarms = {
    node_cpu = {
      metric_name = "node_cpu_utilization", namespace = "ContainerInsights", threshold = var.alarms.cpu_threshold, statistic = "Maximum", description = "Maximum cluster node CPU utilization exceeded the configured percentage."
    }
    node_memory = {
      metric_name = "node_memory_utilization", namespace = "ContainerInsights", threshold = var.alarms.memory_threshold, statistic = "Maximum", description = "Maximum cluster node memory utilization exceeded the configured percentage."
    }
    node_disk_space = {
      metric_name = "node_filesystem_utilization", namespace = "ContainerInsights", threshold = var.alarms.disk_space_threshold, statistic = "Maximum", description = "Cluster node filesystem utilization exceeded the configured percentage."
    }
    node_disk_iops = {
      metric_name = "node_diskio_io_serviced_total", namespace = "ContainerInsights", threshold = var.alarms.disk_iops_threshold, statistic = "Sum", description = "Cluster nodes exceeded the configured disk operations per period."
    }
    node_disk_throughput = {
      metric_name = "node_diskio_io_service_bytes_total", namespace = "ContainerInsights", threshold = var.alarms.disk_throughput_threshold, statistic = "Sum", description = "Cluster nodes exceeded the configured disk bytes transferred per period."
    }
    node_disk_latency = {
      metric_name = "node_diskio_ebs_volume_queue_length", namespace = "ContainerInsights", threshold = var.alarms.disk_latency_queue_threshold, statistic = "Maximum", description = "EBS volume queue depth exceeded the configured latency-pressure proxy threshold."
    }
    node_network_throughput = {
      metric_name = "node_network_total_bytes", namespace = "ContainerInsights", threshold = var.alarms.network_throughput_threshold, statistic = "Maximum", description = "Maximum cluster node network throughput exceeded the configured bytes-per-second threshold."
    }
    node_network_drops = {
      metric_name = "node_interface_network_rx_dropped", namespace = "ContainerInsights", threshold = var.alarms.network_dropped_packets_threshold, statistic = "Sum", description = "Cluster node network receive packet drops exceeded the configured threshold."
    }
    failed_nodes = {
      metric_name = "cluster_failed_node_count", namespace = "ContainerInsights", threshold = var.alarms.failed_node_count_threshold, statistic = "Maximum", description = "The number of failed cluster nodes exceeded the configured threshold."
    }
    unschedulable_pods = {
      metric_name = "scheduler_pending_pods_UNSCHEDULABLE", namespace = "AWS/EKS", threshold = var.alarms.unschedulable_pods_threshold, statistic = "Maximum", description = "The number of unschedulable Kubernetes pods exceeded the configured threshold."
    }
    api_server_5xx = {
      metric_name = "apiserver_request_total_5XX", namespace = "AWS/EKS", threshold = var.alarms.api_server_5xx_threshold, statistic = "Sum", description = "Kubernetes API server 5XX responses exceeded the configured threshold."
    }
    api_server_429 = {
      metric_name = "apiserver_request_total_429", namespace = "AWS/EKS", threshold = var.alarms.api_server_429_threshold, statistic = "Sum", description = "Kubernetes API server throttling responses exceeded the configured threshold."
    }
    api_server_latency = {
      metric_name = "apiserver_request_duration_seconds_GET_P99", namespace = "AWS/EKS", threshold = var.alarms.api_server_latency_seconds_threshold, statistic = "Average", description = "Kubernetes API server GET request p99 latency exceeded the configured seconds threshold."
    }
    etcd_size = {
      metric_name = "etcd_mvcc_db_total_size_in_use_in_bytes", namespace = "AWS/EKS", threshold = var.alarms.etcd_size_bytes_threshold, statistic = "Maximum", description = "Kubernetes etcd in-use database size exceeded the configured bytes threshold."
    }
  }
}
