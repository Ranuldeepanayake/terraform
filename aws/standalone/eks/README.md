# AWS EKS Cluster Terraform Project

This Terraform project creates a complete AWS EKS (Elastic Kubernetes Service) cluster with all necessary networking, security, and access components.

## Architecture Overview

### Network Components
- **VPC**: Uses an existing VPC (provided as variable)
- **Private Subnets (2x)**: For EKS worker nodes with NAT gateway for outbound internet access
- **Public Subnets (2x)**: For NAT gateways and ELB/NLB load balancers created by EKS services
- **NAT Gateways (2x)**: One per availability zone for high availability, allowing nodes to access internet packages/services
- **Route Tables**: Separate routing for private subnets (via NAT) and public subnets (direct internet gateway)

### Security Components
- **Cluster Security Group**: Controls inbound/outbound traffic to EKS control plane
  - Allows worker node communication on port 443 (API server)
  - Allows self-communication within cluster security group
  - Allows all outbound traffic

- **Node Security Group**: Controls inbound/outbound traffic for worker nodes
  - Allows node-to-node communication (TCP and UDP)
  - Allows control plane communication on port 10250 (kubelet API)
  - Allows all outbound traffic

### Compute Components
- **EKS Cluster**: Managed Kubernetes control plane
  - Version configurable (default 1.36)
  - CloudWatch logging enabled for API, audit, and authenticator logs
  - Public and private API endpoint access enabled

- **Managed Node Group**: Managed worker nodes
  - Auto-scaling configuration (default 2-4 nodes)
  - Instance type configurable (default t3.small)
  - Disk size configurable (default 20GB)
  - Deployed in private subnets for security

### Access Control
- **EKS Access Entry**: Grants cluster admin user access
- **Cluster Admin Policy**: Provides full cluster administration permissions
- **IAM Roles**:
  - Cluster role with EKS and VPC resource controller permissions
  - Node role with worker, CNI, container registry, and SSM permissions

## Files Overview

| File | Purpose |
|------|---------|
| `versions.tf` | Provider configuration and version constraints |
| `variables.tf` | Input variables for cluster configuration |
| `main.tf` | EKS cluster resource and CloudWatch logging |
| `subnets.tf` | VPC subnet, NAT gateway, and route table configuration |
| `security_groups.tf` | Security groups for cluster and worker nodes |
| `iam.tf` | IAM roles, policies, and access entry configuration |
| `node_group.tf` | Managed node group with autoscaling |
| `outputs.tf` | Exported values (endpoints, security groups, etc.) |
| `kubeconfig.tpl` | Template for generating kubeconfig file |
| `terraform.tfvars` | Example variable values (update before apply) |
| `CustomPolicyEKSExternalDNS` | IAM permissions required by the Terraform user |

## Prerequisites

1. **AWS Account**: Must have appropriate IAM permissions (see [IAM_POLICY.md](IAM_POLICY.md))
2. **Existing VPC**: A VPC with an internet gateway already attached
3. **Terraform**: Version 1.0 or higher
4. **AWS CLI**: For generating kubeconfig
5. **kubectl**: For interacting with the cluster
6. **ExternalDNS IAM Policy**: The `CustomPolicyEKSExternalDNS` policy must already exist in the AWS account

### IAM Permissions Required

The AWS user running `terraform apply` needs specific permissions to:
- Create EKS cluster, node groups, and add-ons
- Manage VPC resources (subnets, NAT gateways, route tables)
- Create and attach IAM roles
- Create OIDC provider for service account roles (IRSA)
- Create CloudWatch log groups

**See [IAM_POLICY.md](IAM_POLICY.md) for a complete least-privilege policy.**

Quick test: `terraform plan` should show planned resource creation without permission errors.

## Quick Start

### 1. Update Variables

Edit `terraform.tfvars` with your specific values:

```hcl
vpc_id = "vpc-xxxxxxxxx"                    # Your existing VPC ID
cluster_admin_user_arn = "arn:aws:iam::104322896078:user/ranul"  # Your IAM user ARN
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

Deployment typically takes 10-15 minutes for the EKS cluster to become active.

### 5. Configure kubectl

After Terraform completes successfully:

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name eks-cluster
```

Or use the output command directly:

```bash
# Get the command from Terraform output
terraform output configure_kubectl
```

### 6. Verify the Cluster

```bash
kubectl get nodes
kubectl get ns
kubectl cluster-info
```

## Variable Customization

### Cluster Configuration
- `cluster_name`: Name of the EKS cluster (default: `eks-cluster`)
- `cluster_version`: Kubernetes version (default: `1.36`)
- `cluster_upgrade_support_type`: Kubernetes version support policy for the EKS management plane (default: `EXTENDED`)
  - `EXTENDED`: Cluster enters paid extended support after standard support ends
  - `STANDARD`: Cluster opts out of extended support and AWS automatically upgrades it at the end of standard support

### Network Configuration
- `vpc_id`: **REQUIRED** - Your existing VPC ID
- `private_subnet_cidrs`: CIDR blocks for private subnets (default: `10.0.10.0/24`, `10.0.11.0/24`)
- `public_subnet_cidrs`: CIDR blocks for public subnets (default: `10.0.20.0/24`, `10.0.21.0/24`)
- `availability_zones`: AZs for multi-AZ deployment (default: `ap-southeast-1a`, `ap-southeast-1b`)

### Node Group Configuration
- `desired_node_count`: Initial number of nodes (default: `3`)
- `min_node_count`: Minimum nodes for autoscaling (default: `3`)
- `max_node_count`: Maximum nodes for autoscaling (default: `4`)
- `node_instance_types`: EC2 instance types (default: `t3.small`)
- `node_disk_size`: EBS volume size in GB (default: `20`)

### Access Control
- `cluster_admin_user_arn`: **REQUIRED** - IAM user ARN for cluster admin access
  - Format: `arn:aws:iam::ACCOUNT_ID:user/USERNAME`

### ExternalDNS
- `external_dns_policy_name`: Name of the pre-created IAM policy for ExternalDNS Route53 access (default: `CustomPolicyEKSExternalDNS`)
- `external_dns_policy_arn`: Optional full ARN for the ExternalDNS policy. Leave as `null` to build the ARN from `external_dns_policy_name` in the current AWS account.

### Logging
- `enable_cluster_logging`: Control plane log types to enable
  - Options: `api`, `audit`, `authenticator`, `controllerManager`, `scheduler`
  - Default: `["api", "audit", "authenticator"]`

## Outputs

After successful apply, Terraform outputs:

```bash
cluster_id                       # Cluster name
cluster_endpoint                 # API server endpoint
cluster_upgrade_support_type     # EKS version support policy: STANDARD or EXTENDED
cluster_security_group_id        # Control plane security group
node_security_group_id          # Worker node security group
node_group_id                   # Managed node group ID
private_subnet_ids              # Subnet IDs for worker nodes
public_subnet_ids               # Subnet IDs for load balancers
nat_gateway_ips                 # Elastic IPs for NAT gateways
configure_kubectl               # Command to configure kubectl
cloudwatch_log_group_name       # CloudWatch logs location
external_dns_role_arn           # IRSA role used by ExternalDNS
external_dns_policy_arn         # Route53 policy attached to ExternalDNS
```

## Network Flow

### Outbound Traffic (Nodes → Internet)
1. Worker nodes in private subnets initiate outbound connections
2. Traffic routed via route table to NAT gateway in public subnet
3. NAT gateway translates source IP to its Elastic IP
4. Traffic exits via Internet Gateway to the public internet

### Inbound Traffic (ELB/NLB → Nodes)
1. Load balancers are created in public subnets by Kubernetes services
2. Traffic routed directly to nodes via security group rules
3. Nodes accept traffic on specified service ports

## Accessing the Cluster

### From the Admin User

Once the access entry is configured, the cluster admin user can access the cluster:

```bash
# Ensure AWS credentials are configured for the admin user
aws configure --profile admin

# Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name eks-cluster --profile admin

# Access cluster
kubectl get nodes
```

### Adding Additional Users

To grant cluster access to other users, use the `aws_eks_access_entry` resource:

```hcl
resource "aws_eks_access_entry" "developer" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = "arn:aws:iam::ACCOUNT_ID:user/developer-user"
  kubernetes_groups = ["dev-team"]
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "developer" {
  cluster_name       = aws_eks_cluster.main.name
  policy_arn         = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSDeveloperPolicy"
  principal_arn      = "arn:aws:iam::ACCOUNT_ID:user/developer-user"
  access_entry_name  = aws_eks_access_entry.developer.principal_arn
}
```

## EKS Add-ons

This Terraform project automatically deploys and manages essential EKS add-ons. These are AWS-managed components that extend cluster functionality.

### Why Add-ons Are Mandatory

While EKS technically allows cluster creation without add-ons, **they are de facto mandatory for a functional cluster**:

- **VPC CNI** (Container Network Interface) — Without it, pods have no networking layer and cannot communicate
- **CoreDNS** — Without it, service discovery by DNS name fails (no `my-service.default.svc.cluster.local`)
- **kube-proxy** — Without it, Kubernetes services don't load balance traffic between pods
- **EBS CSI Driver** — Without it, applications cannot persist data via PersistentVolumes
- **ExternalDNS** - Without it, Kubernetes Services and Ingresses cannot automatically create or update Route53 DNS records

This project includes them from deployment start because a cluster without these is non-functional. The initial design was overly "minimal" when it should have been "minimal but complete."

### Included Add-ons

All add-ons are automatically deployed and versioned to match your cluster's Kubernetes version. AWS handles patches and updates.

| Add-on | Purpose | Status |
|--------|---------|--------|
| **vpc-cni** | AWS VPC Container Network Interface - handles pod networking | ✅ Auto-deployed |
| **coredns** | DNS for service discovery within the cluster | ✅ Auto-deployed |
| **kube-proxy** | Kubernetes networking proxy - manages service load balancing | ✅ Auto-deployed |
| **aws-ebs-csi-driver** | Enables dynamic EBS volume provisioning as PersistentVolumes | ✅ Auto-deployed |
| **external-dns** | Creates and updates Route53 records from Kubernetes Services and Ingresses | Auto-deployed |

### Verifying Add-ons

After the cluster is created, verify all add-ons are running:

```bash
# View all add-ons
kubectl get pods -n kube-system

# Check specific add-ons
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-node             # VPC CNI
kubectl get pods -n kube-system -l k8s-app=kube-dns                            # CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-proxy                          # kube-proxy
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver   # EBS CSI Driver
kubectl get pods -n external-dns -l app.kubernetes.io/name=external-dns        # ExternalDNS

# View add-on versions and details
aws eks list-addons --cluster-name eks-cluster --region ap-southeast-1
```

### VPC CNI (Container Network Interface)

The VPC CNI driver assigns IP addresses from your VPC to pods, enabling native AWS VPC networking for containers.

**Key Features:**
- Pods get VPC IPs directly from your subnets
- Native VPC security groups can be applied to pods
- Supports high-performance networking

**Verify VPC CNI:**
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-node -o wide
```

### CoreDNS

Provides DNS name resolution for Kubernetes services, enabling service discovery by name (e.g., `my-service.default.svc.cluster.local`).

**Verify CoreDNS:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

### kube-proxy

Maintains network rules on nodes to enable service networking, load balancing, and network policies.

**Verify kube-proxy:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy
```

### EBS CSI Driver

Enables Kubernetes to dynamically provision and manage EBS volumes as PersistentVolumes. This allows applications to request storage via PersistentVolumeClaims.

**Verify EBS CSI Driver:**
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

### ExternalDNS

ExternalDNS watches Kubernetes Services and Ingresses and keeps matching Route53 DNS records in sync. It is deployed as an EKS community add-on in the default `external-dns` namespace.

The service account uses IRSA with the pre-created `CustomPolicyEKSExternalDNS` policy. By default, Terraform builds the policy ARN as:

```text
arn:aws:iam::<ACCOUNT_ID>:policy/CustomPolicyEKSExternalDNS
```

If the policy uses a non-default path or a different account, set `external_dns_policy_arn` explicitly in `terraform.tfvars`.

**Verify ExternalDNS:**
```bash
kubectl get pods -n external-dns -l app.kubernetes.io/name=external-dns
aws eks describe-addon --cluster-name eks-cluster --addon-name external-dns --region ap-southeast-1
```

**Example Service annotation:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app
  annotations:
    external-dns.alpha.kubernetes.io/hostname: app.example.com
spec:
  type: LoadBalancer
  selector:
    app: app
  ports:
    - port: 80
      targetPort: 8080
```

### Updating Add-on Versions

Add-on versions are automatically set to the latest compatible version for your cluster Kubernetes version. To update manually:

```bash
# Check available versions for an add-on
aws eks describe-addon-versions \
  --addon-name vpc-cni \
  --kubernetes-version 1.36 \
  --region ap-southeast-1

# Update add-on to specific version
aws eks update-addon \
  --cluster-name eks-cluster \
  --addon-name vpc-cni \
  --addon-version 1.15.0-eksbuild.1 \
  --region ap-southeast-1
```

### Add-on Health and Troubleshooting

If an add-on fails to deploy or becomes unhealthy:

```bash
# Check add-on status
aws eks describe-addon \
  --cluster-name eks-cluster \
  --addon-name vpc-cni \
  --region ap-southeast-1

# View add-on events and health
aws eks describe-addon --cluster-name eks-cluster --addon-name vpc-cni --region ap-southeast-1 --query 'addon.health'

# Check pod logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-node --tail=50
```

## Storage & PersistentVolumes

The EBS CSI driver add-on enables dynamic provisioning of EBS volumes as PersistentVolumes. The necessary IAM permissions are automatically configured through IRSA (IAM Roles for Service Accounts).

### Creating StorageClass and PersistentVolumeClaim

The EBS CSI Driver is already deployed. Create a StorageClass to define volume behavior:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  deleteOnTermination: "true"
allowVolumeExpansion: true
```

Then create a PersistentVolumeClaim to request storage:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 10Gi
```

Once applied, Kubernetes automatically:
1. Provisions an EBS volume
2. Attaches it to the appropriate node
3. Mounts it to the pod

### Storage Class Parameters

| Parameter | Purpose | Example |
|-----------|---------|---------|
| `type` | EBS volume type | gp3, gp2, io1, io2 |
| `iops` | I/O operations per second | 3000-16000 for gp3 |
| `throughput` | Throughput in MB/s | 125-1000 for gp3 |
| `deleteOnTermination` | Delete volume when PVC is deleted | true/false |

## Accessing Worker Nodes

Worker nodes are in private subnets and can be accessed via two methods:

### Method 1: AWS Systems Manager Session Manager (Recommended)

No SSH key required. Requires SSM agent on instances (included in EKS AMI) and IAM permissions.

```bash
# Find instance IDs
aws ec2 describe-instances \
  --filters Name=tag:eks:nodegroup-name,Values=eks-node-group \
  --region ap-southeast-1 \
  --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress]'

# Start a session to the instance
aws ssm start-session --target <INSTANCE_ID> --region ap-southeast-1

# Inside the session, switch to ec2-user
sudo su - ec2-user
```

### Method 2: EC2 SSH Key Pair (Optional)

To enable SSH access, provide an EC2 key pair name in `terraform.tfvars`:

```hcl
ec2_ssh_key_name = "my-eks-key"
```

Then SSH to nodes via their private IP:

```bash
# Port forward through a bastion or use AWS Systems Manager port forwarding
aws ssm start-session \
  --target <INSTANCE_ID> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["9999"]}' \
  --region ap-southeast-1

# In another terminal
ssh -i my-eks-key.pem -p 9999 ec2-user@localhost
```

## Monitoring & Logging

### CloudWatch Logs

Control plane logs are available in CloudWatch:

```bash
aws logs tail /aws/eks/eks-cluster/cluster --follow
```

### Cluster Autoscaling

The managed node group is tagged appropriately for Cluster Autoscaler:
- `k8s.io/cluster-autoscaler/eks-cluster = owned`
- `k8s.io/cluster-autoscaler/enabled = true`

To deploy Cluster Autoscaler:

```bash
# Deploy Cluster Autoscaler using Helm
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=eks-cluster \
  --set awsRegion=ap-southeast-1
```

### Viewing Terraform Outputs

After deployment, view helpful information about storage and node access:

```bash
# Display all outputs
terraform output

# View specific information
terraform output node_access_methods
terraform output storage_provisioning_steps
terraform output ebs_csi_driver_info
```


## Cleanup

To destroy all resources:

```bash
terraform destroy
```

This will remove:
- EKS cluster and node group
- VPC subnets, NAT gateways, and route tables
- Security groups and IAM roles
- CloudWatch log group

## Cost Estimation

Approximate monthly costs (US East 1):
- EKS cluster: $73/month
- 2x t3.medium nodes: ~$30/month (if reserved)
- NAT gateways: ~$32/month (2x gateways)
- Data transfer: Variable

**Total base cost: ~$150-200/month** (varies by region and data transfer)

## Troubleshooting

### Nodes not joining cluster
- Check security group rules allow communication on ports 443 and 10250
- Verify node role has required IAM policies attached
- Check EC2 instance logs: `aws ec2 get-console-output --instance-id <id>`

### Cannot access cluster API
- Verify cluster admin user ARN is correctly specified
- Check that user has EC2/IAM permissions
- Ensure kubeconfig is properly configured: `kubectl config view`

### VPC/Subnet CIDR conflicts
- Ensure CIDR blocks don't overlap with existing VPC subnets
- Update `private_subnet_cidrs` and `public_subnet_cidrs` variables
- Verify availability zones match your region

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Support

For issues or questions:
1. Check Terraform state: `terraform state list`
2. View resource details: `terraform state show <resource>`
3. Check AWS CloudWatch logs for cluster diagnostics
4. Review security group rules and IAM permissions
