# Re-export module outputs at the environment boundary for Terraform Cloud and
# downstream remote-state consumers.
output "cluster_id" {
  description = "EKS cluster name."
  value       = module.eks_cluster.cluster_id
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks_cluster.cluster_arn
}

output "node_group_id" {
  description = "Managed node group ID."
  value       = module.eks_cluster.node_group_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by worker nodes."
  value       = module.eks_cluster.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by load balancers and NAT gateways."
  value       = module.eks_cluster.public_subnet_ids
}

output "configure_kubectl_command" {
  description = "AWS CLI command for configuring kubectl."
  value       = module.eks_cluster.configure_kubectl_command
}

output "kubeconfig_path" {
  description = "Generated kubeconfig path, or null when generation is disabled."
  value       = module.eks_cluster.kubeconfig_path
}

output "cloudwatch_log_group_name" {
  description = "EKS control-plane log group name."
  value       = module.eks_cluster.cloudwatch_log_group_name
}
