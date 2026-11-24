# EKS cluster environment caller

This root configuration owns the AWS provider and Terraform Cloud workspace,
passes environment values directly in `main.tf`, and calls the reusable
[`../../modules/eks-cluster`](../../modules/eks-cluster) module.

Review the VPC ID, IAM principals, Route 53 zone IDs, SSH key name, endpoint
exposure, and tags in the module arguments in `main.tf` before applying. The
caller preserves the values from the original standalone EKS configuration as
a starting point.

```powershell
Set-Location aws/module-instances/eks-cluster
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

The caller re-exports the primary cluster, network, node group, kubeconfig, and
log group outputs for remote-state consumers.

## Monitoring

The caller enables the module's standard CloudWatch node and EKS control-plane
alarms using `alarms.enabled = true` in `main.tf`. It also demonstrates a
caller-defined disk-pressure alarm. Set `enabled = false` to disable the alarms,
observability add-on, and its conditional node-role policy attachment. Configure
alarm thresholds in the `alarms` object, optionally set `alarm_sns_topic_name`,
or pass `alarm_sns_topic_arn` to reuse an existing standard topic. Add multiple
recipients to `alarm_email_addresses`; each recipient must confirm the SNS
subscription email before alerts arrive. The selected topic is automatically
attached to built-in and custom alarms. `alarm_actions` can add other
notification actions. Add or remove custom metrics through `additional_alarms`.
If both topic inputs are `null`, the module creates `<cluster-name>-alerts`. If
both are set, `alarm_sns_topic_arn` takes precedence and the supplied name is
ignored.
The example caller leaves `alarm_email_addresses` empty because no recipients
were provided; add the target addresses there to receive email alerts.
The caller exports `alarm_arns` and `alarm_names` for downstream use. See the
module README for the covered metrics, assumptions, and custom-alarm schema.
