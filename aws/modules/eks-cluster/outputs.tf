#============================================================
# CLUSTER OUTPUTS
#============================================================

output "cluster_id" {
  description = "The ID/name of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes server version"
  value       = aws_eks_cluster.main.version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

output "cluster_platform_version" {
  description = "Platform version of the cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_upgrade_support_type" {
  description = "EKS Kubernetes version support policy for the cluster"
  value       = var.cluster_upgrade_support_type
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

#============================================================
# SECURITY & NETWORKING OUTPUTS
#============================================================

output "cluster_security_group_id" {
  description = "Security group ID for EKS control plane"
  value       = aws_security_group.cluster.id
}

output "cluster_security_group_name" {
  description = "Security group name for EKS control plane"
  value       = aws_security_group.cluster.name
}

output "node_security_group_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.nodes.id
}

output "node_security_group_name" {
  description = "Security group name for worker nodes"
  value       = aws_security_group.nodes.name
}

output "eks_managed_node_group_cluster_security_group_id" {
  description = "EKS-created cluster security group ID. Include it when a custom launch template specifies security groups."
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs for worker nodes"
  value       = aws_subnet.private[*].id
}

output "private_subnet_details" {
  description = "Detailed information about private subnets"
  value = [
    for i, subnet in aws_subnet.private : {
      id                = subnet.id
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  ]
}

output "public_subnet_ids" {
  description = "List of public subnet IDs for load balancers and NAT gateways"
  value       = aws_subnet.public[*].id
}

output "public_subnet_details" {
  description = "Detailed information about public subnets"
  value = [
    for i, subnet in aws_subnet.public : {
      id                = subnet.id
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  ]
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateways (nodes use these for outbound internet access)"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_details" {
  description = "Detailed information about NAT Gateways"
  value = [
    for i, nat in aws_nat_gateway.nat : {
      id                = nat.id
      public_ip         = aws_eip.nat[i].public_ip
      subnet_id         = nat.subnet_id
      availability_zone = aws_subnet.public[i].availability_zone
    }
  ]
}

#============================================================
# NODE GROUP OUTPUTS
#============================================================

output "node_groups" {
  description = "Managed node group details keyed by node_groups input key."
  value = {
    for key, group in aws_eks_node_group.this : key => {
      id             = group.id
      arn            = group.arn
      name           = group.node_group_name
      status         = group.status
      version        = group.version
      capacity_type  = group.capacity_type
      instance_types = group.instance_types
      disk_size      = group.disk_size
      scaling_config = group.scaling_config[0]
      subnet_ids     = group.subnet_ids
    }
  }
}

#============================================================
# IAM & ACCESS OUTPUTS
#============================================================

output "cluster_iam_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.arn
}

output "node_iam_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.nodes.arn
}

output "node_iam_instance_profile" {
  description = "Name of the node IAM instance profile"
  value       = aws_iam_instance_profile.nodes.name
}

output "eks_access_configuration" {
  description = "EKS access entries and associated policies."

  value = {
    for name, entry in var.eks_access_entries : name => {
      principal_arn = aws_eks_access_entry.principals[name].principal_arn
      policy_arn    = aws_eks_access_policy_association.principals[name].policy_arn
      access_scope  = aws_eks_access_policy_association.principals[name].access_scope
    }
  }
}

output "vpc_cni_role_arn" {
  description = "ARN of the VPC CNI service account role (IRSA)"
  value       = aws_iam_role.vpc_cni.arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI Driver service account role (IRSA)"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "external_dns_role_arn" {
  description = "ARN of the ExternalDNS service account role (IRSA)"
  value       = aws_iam_role.external_dns.arn
}

output "external_dns_policy_arn" {
  description = "ARN of the IAM policy attached to the ExternalDNS service account role"
  value       = local.external_dns_policy_arn
}

#============================================================
# ADD-ONS OUTPUTS
#============================================================

output "enabled_addons" {
  description = "List of enabled EKS add-ons with versions"
  value = {
    vpc-cni            = aws_eks_addon.vpc_cni.addon_version
    coredns            = aws_eks_addon.coredns.addon_version
    kube-proxy         = aws_eks_addon.kube_proxy.addon_version
    aws-ebs-csi-driver = aws_eks_addon.ebs_csi_driver.addon_version
    external-dns       = aws_eks_addon.external_dns.addon_version
  }
}

output "vpc_cni_addon_status" {
  description = "Status of VPC CNI add-on"
  value       = aws_eks_addon.vpc_cni.addon_version
}

output "coredns_addon_status" {
  description = "Status of CoreDNS add-on"
  value       = aws_eks_addon.coredns.addon_version
}

output "kube_proxy_addon_status" {
  description = "Status of kube-proxy add-on"
  value       = aws_eks_addon.kube_proxy.addon_version
}

output "ebs_csi_driver_addon_status" {
  description = "Status of EBS CSI Driver add-on"
  value       = aws_eks_addon.ebs_csi_driver.addon_version
}

output "external_dns_addon_status" {
  description = "Status of ExternalDNS add-on"
  value       = aws_eks_addon.external_dns.addon_version
}

#============================================================
# KUBECONFIG & CONNECTIVITY
#============================================================

output "kubeconfig_path" {
  description = "Local path to generated kubeconfig file"
  value       = var.kubeconfig_path
}

output "configure_kubectl_command" {
  description = "Command to configure kubectl to use this cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "kubectl_cluster_info" {
  description = "Command to view cluster information"
  value       = "kubectl cluster-info"
}

output "kubectl_get_nodes" {
  description = "Command to list all worker nodes"
  value       = "kubectl get nodes -o wide"
}

#============================================================
# NODE ACCESS OUTPUTS
#============================================================

output "node_access_methods" {
  description = "Methods and commands to access worker nodes in each managed node group."
  value = {
    description = "Use Systems Manager by default. SSH is configured per node group."
    ssm_session_manager = {
      description   = "Recommended: No SSH key required, all actions are logged"
      start_session = "aws ssm start-session --target <INSTANCE_ID> --region ${var.aws_region}"
      switch_user   = "sudo su - ec2-user"
    }
    groups = {
      for key, group in var.node_groups : key => {
        node_group_name = group.node_group_name
        list_instances  = "aws ec2 describe-instances --filters Name=tag:eks:nodegroup-name,Values=${group.node_group_name} --region ${var.aws_region} --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress]' --output table"
        ssh_key_name    = try(group.remote_access.ec2_ssh_key, null)
        ssh_example     = try(group.remote_access.ec2_ssh_key, null) == null ? null : "ssh -i /path/to/${group.remote_access.ec2_ssh_key}.pem ec2-user@<PRIVATE_IP>"
      }
    }
  }
}

#============================================================
# STORAGE OUTPUTS
#============================================================

output "storage_info" {
  description = "Information about persistent storage provisioning"
  value = {
    ebs_csi_driver_enabled = "YES - Add-on deployed and ready"
    description            = "EBS volumes can be dynamically provisioned as PersistentVolumes"
    create_storage_class   = "kubectl apply -f storage-class.yaml (see README for example)"
    verify_driver          = "kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver"
    gp3_default            = "Recommended: gp3 volumes with configurable IOPS and throughput"
    ebs_policy_attached    = "YES - Node IAM role has AmazonEBSCSIDriverPolicy"
  }
}

#============================================================
# LOGGING & MONITORING OUTPUTS
#============================================================

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group for EKS control plane logs"
  value       = aws_cloudwatch_log_group.cluster.name
}

output "cloudwatch_log_retention_days" {
  description = "Log retention period in days"
  value       = var.cloudwatch_log_retention_days
}

output "view_logs_command" {
  description = "Command to view control plane logs in CloudWatch"
  value       = "aws logs tail ${aws_cloudwatch_log_group.cluster.name} --follow --region ${var.aws_region}"
}

output "enabled_log_types" {
  description = "Control plane log types enabled"
  value       = var.enable_cluster_logging
}

#============================================================
# POST-DEPLOYMENT CHECKLIST
#============================================================

output "post_deployment_steps" {
  description = "Steps to complete after cluster deployment"
  value       = <<-EOT
    ✓ CLUSTER CREATED - Next steps:
    
    1. CONFIGURE KUBECTL
       ${replace("aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}", "\n", "")}
    
    2. VERIFY CLUSTER
       kubectl get nodes              # List all nodes
       kubectl get pods -A            # List all pods
       kubectl get svc -A             # List all services
    
    3. VERIFY ADD-ONS
       kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-node              # VPC CNI
       kubectl get pods -n kube-system -l k8s-app=kube-dns                             # CoreDNS
       kubectl get pods -n kube-system -l k8s-app=kube-proxy                                                        # kube-proxy
       kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver    # EBS CSI Driver
       kubectl get pods -n external-dns -l app.kubernetes.io/name=external-dns         # ExternalDNS
    
    4. CREATE STORAGE CLASS (for PersistentVolumes)
       kubectl apply -f - <<YAML
       apiVersion: storage.k8s.io/v1
       kind: StorageClass
       metadata:
         name: ebs-sc
       provisioner: ebs.csi.aws.com
       volumeBindingMode: WaitForFirstConsumer
       allowVolumeExpansion: true
       reclaimPolicy: Delete
       parameters:
         type: gp3
         iops: "3000"
         throughput: "125"
       YAML
    
    5. ACCESS WORKER NODES
       Option A (Recommended): AWS Systems Manager Session Manager
         aws ssm start-session --target <INSTANCE_ID> --region ${var.aws_region}
       
       Option B: SSH with key pair (if configured)
         ssh -i key.pem ec2-user@<PRIVATE_IP>
    
    6. DEPLOY INGRESS CONTROLLER (nginx)
       helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
       helm install nginx-ingress ingress-nginx/ingress-nginx \
         --namespace ingress-nginx --create-namespace \
         --set controller.service.type=LoadBalancer

       ExternalDNS will create/update Route53 records for compatible Services and Ingresses.
    
    7. MONITOR LOGS
       aws logs tail ${aws_cloudwatch_log_group.cluster.name} --follow --region ${var.aws_region}
    
    8. VERIFY NETWORKING
       kubectl run test-pod --image=nginx --rm -it -- sh
       inside container: curl http://kubernetes.default (should succeed)
    
    CLUSTER DETAILS:
      Name:     ${aws_eks_cluster.main.name}
      Region:   ${var.aws_region}
      Version:  ${aws_eks_cluster.main.version}
      Support:  ${var.cluster_upgrade_support_type}
      Status:   ${aws_eks_cluster.main.status}
      Endpoint: ${aws_eks_cluster.main.endpoint}
  EOT
}

#============================================================
# TROUBLESHOOTING OUTPUTS
#============================================================

output "troubleshooting_commands" {
  description = "Common troubleshooting commands"
  value = {
    check_node_status  = "kubectl describe node <NODE_NAME>"
    check_node_logs    = "aws ssm start-session --target <INSTANCE_ID> -- sh -c 'journalctl -u kubelet -n 50'"
    check_pod_status   = "kubectl describe pod <POD_NAME> -n <NAMESPACE>"
    check_events       = "kubectl get events -A --sort-by='.lastTimestamp'"
    check_addon_status = "aws eks describe-addon --cluster-name ${aws_eks_cluster.main.name} --addon-name vpc-cni --region ${var.aws_region}"
  }
}

# Expose alarm ARNs and names so callers can connect dashboards or downstream automation.
output "alarm_arns" {
  description = "ARNs for built-in and caller-defined CloudWatch alarms."
  value = merge(
    { for key, alarm in aws_cloudwatch_metric_alarm.builtin : key => alarm.arn },
    { for key, alarm in aws_cloudwatch_metric_alarm.additional : key => alarm.arn },
  )
}

output "alarm_names" {
  description = "Names for built-in and caller-defined CloudWatch alarms."
  value = merge(
    { for key, alarm in aws_cloudwatch_metric_alarm.builtin : key => alarm.alarm_name },
    { for key, alarm in aws_cloudwatch_metric_alarm.additional : key => alarm.alarm_name },
  )
}
