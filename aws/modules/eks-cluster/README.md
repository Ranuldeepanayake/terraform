# Reusable AWS EKS cluster module

This directory is a reusable Terraform module for an EKS cluster with managed
nodes, VPC subnets and NAT gateways, IAM/IRSA roles, managed EKS add-ons,
control-plane logging, and cert-manager Route 53 pod identity.

The module does not configure AWS, Helm, Terraform Cloud, or a workspace. Those
settings belong in a root caller. A ready-to-run environment caller is in
[`../../module-instances/eks-cluster`](../../module-instances/eks-cluster), with
the original standalone values preserved in its `terraform.tfvars`.

## Usage

```hcl
module "eks_cluster" {
  source = "../../modules/eks-cluster"

  aws_region           = var.aws_region
  vpc_id               = var.vpc_id
  cluster_name         = var.cluster_name
  cluster_version      = var.cluster_version
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  availability_zones   = var.availability_zones
  route53_zones        = var.route53_zones
  tags                 = var.tags
}
```

All deployment-specific values are inputs. In addition to the original
standalone inputs, the module exposes `kubeconfig_path`, route CIDRs,
security-group egress/ingress CIDRs, and managed add-on conflict behavior.
Set `kubeconfig_path = null` (the default) to avoid creating a local file from
the module. The module returns the configured path as `kubeconfig_path`.

The module creates private and public subnets inside the supplied VPC. The VPC
must already have an attached internet gateway. Private subnets use one NAT
gateway per public subnet, so the number of private and public CIDRs should
match the number of availability zones.

## CloudWatch alarms

The caller can enable the module's built-in node and EKS control-plane alarms
and pass additional metric alarms. Set `alarms.enabled = true` to install the
CloudWatch Observability EKS add-on, attach `CloudWatchAgentServerPolicy` to the
node role, enable EBS CSI volume metrics, and create the built-in alarms. With
the default `enabled = false`, existing cluster behavior is preserved and no
monitoring add-on, IAM attachment, or alarms are created.

```hcl
alarms = {
  enabled                  = true
  cpu_threshold            = 80
  memory_threshold         = 80
  disk_space_threshold     = 80
  disk_iops_threshold      = 10000
  disk_throughput_threshold = 100000000
}

alarm_sns_topic_name = "production-eks-alerts" # Optional; defaults to "<cluster-name>-alerts".
alarm_sns_topic_arn  = null                    # Set an existing standard SNS topic ARN to reuse it.
alarm_email_addresses = [
  "platform@example.com",
  "oncall@example.com",
]
alarm_actions = [] # Optional extra action ARNs in addition to the email topic.

additional_alarms = {
  node_disk_pressure = {
    metric_name         = "node_status_condition_disk_pressure"
    namespace           = "ContainerInsights"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    period              = 300
    statistic           = "Maximum"
    threshold           = 0
    dimensions          = { ClusterName = var.cluster_name }
  }
}
```

Built-in alarms cover cluster node CPU, memory, filesystem use, disk operations,
disk throughput, EBS queue depth, network throughput and packet drops, failed
nodes, unschedulable pods, API-server 5XX/429 responses and GET p99 latency, and
etcd in-use database size. All built-in thresholds, the period, and missing-data
behavior can be set in the `alarms` object. The selected SNS topic is always
included in built-in and custom alarm actions. Set `alarm_sns_topic_name` to
choose a name for the module-created standard topic, or set
`alarm_sns_topic_arn` to reuse an existing standard topic instead. The caller
may subscribe multiple recipients through `alarm_email_addresses`; SNS sends
each recipient a confirmation email, and delivery begins after confirmation.
If both topic inputs are `null`, the module creates a topic named
`<cluster-name>-alerts`. If both are set, `alarm_sns_topic_arn` takes
precedence and `alarm_sns_topic_name` is ignored.
`alarm_actions` and `alarm_ok_actions` add optional state-change actions;
custom alarms may supply additional actions individually. `additional_alarms`
follow the EC2 module's custom alarm shape and are created only when
`alarms.enabled` is true. The module exports `alarm_arns` and `alarm_names`.

Container Insights publishes cluster-rollup node metrics with the `ClusterName`
dimension; use caller-defined alarms with `InstanceId` or `NodeName` dimensions
when targeting a specific node. Disk queue depth is an indicator of storage
latency pressure, not a direct latency measurement. EKS does not publish a
general node-to-node latency metric; API-server request p99 latency and node
packet-drop alarms provide control-plane latency and network-health signals.
Container Insights has CloudWatch usage charges. Review AWS pricing and metric
availability for the selected region and add-on versions before enabling it.

## Caller workflow

```powershell
Set-Location aws/module-instances/eks-cluster
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Review `terraform.tfvars` before applying. It contains environment-specific
AWS identifiers and access principals and should not be copied into another
environment without review. See [`IAM_POLICY.md`](./IAM_POLICY.md) for the
deployment permissions required by the Terraform identity.

## Important behavior

- EKS add-on data sources select the most recent versions compatible with
  `cluster_version`.
- `addon_conflict_resolution` defaults to `OVERWRITE` to preserve standalone
  behavior.
- `endpoint_public_access` and the default load-balancer CIDRs intentionally
  allow internet access; restrict them for private deployments.
- The node group ignores externally managed desired-size changes, matching the
  original configuration's autoscaler-friendly behavior.
- Validation does not prove AWS permissions, cluster readiness, or node health;
  those require a live plan/apply and post-deployment AWS/Kubernetes checks.
