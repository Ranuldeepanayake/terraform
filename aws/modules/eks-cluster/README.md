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
