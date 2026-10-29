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
