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

output "node_group_id" {
  description = "Managed node group ID"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "ARN of the managed node group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the managed node group (CREATING, ACTIVE, UPDATING, DELETING, CREATE_FAILED, DELETE_FAILED, DEGRADED)"
  value       = aws_eks_node_group.main.status
}

output "node_group_version" {
  description = "Kubernetes version of the node group"
  value       = aws_eks_node_group.main.version
}

output "node_scaling_config" {
  description = "Scaling configuration for the node group"
  value = {
    desired_size = aws_eks_node_group.main.scaling_config[0].desired_size
    max_size     = aws_eks_node_group.main.scaling_config[0].max_size
    min_size     = aws_eks_node_group.main.scaling_config[0].min_size
  }
}

output "node_instance_types" {
  description = "Instance types used for worker nodes"
  value       = aws_eks_node_group.main.instance_types
}

output "node_disk_size_gb" {
  description = "EBS volume size for worker nodes in GiB"
  value       = aws_eks_node_group.main.disk_size
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

output "cluster_admin_user_arn" {
  description = "ARN of the IAM user with cluster admin access"
  value       = var.cluster_admin_user_arn
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
  value       = local_file.kubeconfig.filename
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
  description = "Methods to access worker nodes"
  value = {
    description = "Two ways to access nodes"
    ssm_session_manager = {
      description    = "Recommended: No SSH key required, all actions are logged"
      list_instances = "aws ec2 describe-instances --filters Name=tag:eks:nodegroup-name,Values=${var.node_group_name} --region ${var.aws_region} --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress]' --output table"
      start_session  = "aws ssm start-session --target <INSTANCE_ID> --region ${var.aws_region}"
      switch_user    = "sudo su - ec2-user"
    }
    ec2_ssh = {
      description = "Optional: Requires EC2 key pair (set ec2_ssh_key_name in terraform.tfvars)"
      enabled     = var.ec2_ssh_key_name != null ? "YES" : "NO (configure ec2_ssh_key_name to enable)"
      key_name    = var.ec2_ssh_key_name
      example     = "ssh -i /path/to/${var.ec2_ssh_key_name != null ? var.ec2_ssh_key_name : "KEY"}.pem ec2-user@<PRIVATE_IP>"
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
