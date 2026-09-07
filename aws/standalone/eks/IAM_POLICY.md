# IAM Policy for EKS Terraform Deployment

This document outlines the IAM permissions required for an AWS user to deploy this EKS Terraform project.

## Quick Reference: Minimum Policy

For the user running `terraform apply`, attach this managed policy:
- `AdministratorAccess` (simplest, not recommended for production)

For production, use the least-privilege policy below.

## Production: Least-Privilege Policy

> **⚠️ Important**: If you see `AccessDeniedException: User is not authorized to perform this action` for `DescribeAddonVersions`, ensure your IAM policy includes the `eks:DescribeAddonVersions` action (see EKSAddOnManagement section below). This is required for Terraform to query compatible add-on versions during planning.

# The policy can be created as 'CustomPolicyEKSTerraformDeployment'.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EKSReadOnlyGlobal",
            "Effect": "Allow",
            "Action": [
                "eks:DescribeAddon",
                "eks:DescribeAddonVersions",
                "eks:DescribeCluster",
                "eks:DescribeNodegroup",
                "eks:DescribeAddon",
                "eks:DescribeUpdate",
                "eks:ListClusters",
                "eks:ListNodegroups",
                "eks:ListAddons",
                "eks:ListAccessEntries",
                "eks:ListAccessPolicies",
                "eks:ListAssociatedAccessPolicies",
                "eks:ListUpdates"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EKSManagement",
            "Effect": "Allow",
            "Action": [
                "eks:CreateCluster",
                "eks:DeleteCluster",
                "eks:UpdateClusterVersion",
                "eks:CreateNodegroup",
                "eks:DeleteNodegroup",
                "eks:CreateAddon",
                "eks:UpdateAddon",
                "eks:DeleteAddon",
                "eks:CreateAccessEntry",
                "eks:UpdateAccessEntry",
                "eks:UpdateNodegroupConfig",
                "eks:DeleteAccessEntry",
                "eks:AssociateAccessPolicy",
                "eks:DisassociateAccessPolicy",
                "eks:TagResource",
                "eks:UntagResource",
                "eks:ListTagsForResource"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EC2ReadOnly",
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EC2Networking",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSubnet",
                "ec2:DeleteSubnet",
                "ec2:ModifySubnetAttribute",
                "ec2:CreateRouteTable",
                "ec2:DeleteRouteTable",
                "ec2:AssociateRouteTable",
                "ec2:DisassociateRouteTable",
                "ec2:CreateRoute",
                "ec2:DeleteRoute",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:AllocateAddress",
                "ec2:ReleaseAddress",
                "ec2:CreateNatGateway",
                "ec2:DeleteNatGateway"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMManagement",
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:UpdateAssumeRolePolicy",
                "iam:TagRole",
                "iam:UntagRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:CreateOpenIDConnectProvider",
                "iam:DeleteOpenIDConnectProvider",
                "iam:TagOpenIDConnectProvider",
                "iam:UntagOpenIDConnectProvider",
                "iam:PassRole",
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMReadOnly",
            "Effect": "Allow",
            "Action": [
                "iam:Get*",
                "iam:List*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudWatchLogs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:DeleteLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy",
                "logs:TagLogGroup",
                "logs:UntagLogGroup",
                "logs:ListTagsLogGroup",
                "logs:ListTagsForResource"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Autoscaling",
            "Effect": "Allow",
            "Action": [
                "autoscaling:Describe*",
                "autoscaling:CreateOrUpdateTags",
                "autoscaling:DeleteTags"
            ],
            "Resource": "*"
        },
        {
            "Sid": "STS",
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

## Detailed Permission Breakdown

### 1. EKS Cluster Operations
- `eks:CreateCluster` - Create the EKS cluster
- `eks:DescribeCluster` - Read cluster details
- `eks:UpdateCluster` - Update cluster configuration
- `eks:DeleteCluster` - Delete cluster
- `eks:TagResource` - Add tags to cluster

### 2. EKS Node Group Operations
- `eks:CreateNodegroup` - Create managed node group
- `eks:DescribeNodegroup` - Read node group details
- `eks:UpdateNodegroup` - Modify node group settings
- `eks:DeleteNodegroup` - Delete node group

### 3. EKS Add-ons Operations
- `eks:CreateAddon` - Deploy add-ons (VPC CNI, CoreDNS, etc.)
- `eks:DescribeAddon` - Check add-on status
- `eks:UpdateAddon` - Update add-on versions
- `eks:DescribeAddonVersions` - List available add-on versions

### 4. EKS Access Management
- `eks:CreateAccessEntry` - Create cluster access for users
- `eks:AssociateAccessPolicy` - Attach policies to access entries
- Required for cluster admin user configuration

### 5. VPC & Networking
- **Subnets**: Create/delete private and public subnets
- **Route Tables**: Create routes for internet gateway and NAT gateways
- **Security Groups**: Create and configure cluster and node security groups
- **NAT Gateways**: Create/delete NAT gateways for node internet access
- **Elastic IPs**: Allocate/release IPs for NAT gateways

### 6. IAM Roles & Policies
- **Cluster Role**: Role for EKS control plane to manage AWS resources
- **Node Role**: Role for EC2 instances to join cluster and access AWS services
- **Service Account Roles (IRSA)**: Roles for add-ons:
  - VPC CNI service account
  - EBS CSI Driver service account
- **Instance Profiles**: Attach roles to EC2 instances

### 7. OIDC Provider (for IRSA)
- `iam:CreateOpenIDConnectProvider` - Enable IAM roles for service accounts
- Required for VPC CNI and EBS CSI Driver to assume roles in-cluster

### 8. CloudWatch Logging
- `logs:CreateLogGroup` - Create log group for control plane logs
- `logs:PutRetentionPolicy` - Set log retention
- `logs:DeleteLogGroup` - Clean up logs

### 9. Auto Scaling Groups
- `autoscaling:DescribeAutoScalingGroups` - Read ASG details
- `autoscaling:CreateOrUpdateTags` - Tag ASGs for cluster autoscaler

## Implementation Steps

### Step 1: Create Policy in AWS Console

1. Go to IAM → Policies → Create Policy
2. Choose JSON tab
3. Paste the least-privilege policy above (replace `ACCOUNT_ID`)
4. Name it: `CustomPolicyEKSTerraformDeployment `
5. Create policy

### Step 2: Attach to User

1. Go to IAM → Users → Select user
2. Add permissions → Attach policies directly
3. Search for `CustomPolicyEKSTerraformDeployment `
4. Attach

### Step 3: Verify AWS CLI Credentials

```bash
# Verify credentials are configured
aws sts get-caller-identity

# Should return:
# {
#     "UserId": "AIDAI...",
#     "Account": "104322896078",
#     "Arn": "arn:aws:iam::104322896078:user/your-username"
# }
```

### Step 4: Test Terraform

```bash
cd /home/ranul/repos/cloud/terraform/aws/standalone/eks
terraform plan
```

If you see resource creation plans, permissions are correct.

## Policy Validation Checklist

| Resource | Required Permissions | Example |
|----------|----------------------|---------|
| **EKS Cluster** | CreateCluster, DescribeCluster, UpdateCluster, DeleteCluster | Core cluster lifecycle |
| **Node Groups** | CreateNodegroup, DescribeNodegroup, UpdateNodegroup | EC2 instance management |
| **Add-ons** | CreateAddon, UpdateAddon, DescribeAddonVersions | VPC CNI, CoreDNS, EBS CSI |
| **VPC Subnets** | CreateSubnet, DeleteSubnet, CreateTags | Private and public subnets |
| **NAT Gateways** | CreateNatGateway, AllocateAddress | Internet egress for nodes |
| **Security Groups** | CreateSecurityGroup, AuthorizeSecurityGroupIngress | Network access control |
| **IAM Roles** | CreateRole, AttachRolePolicy | Cluster and node permissions |
| **OIDC Provider** | CreateOpenIDConnectProvider | Service account roles (IRSA) |
| **CloudWatch** | CreateLogGroup, PutRetentionPolicy | Control plane logs |

## Troubleshooting Permission Issues

If Terraform fails with permission errors:

1. **Check the error message** - it specifies which action failed
2. **Find the action in the policy** - verify it's included
3. **Verify user attachment** - `aws iam list-user-policies --user-name <username>`
4. **Check inline policies** - `aws iam get-user-policy --user-name <username> --policy-name <policy>`

### Common Error Examples

**Error**: `User is not authorized to perform: eks:CreateCluster`
- **Fix**: Add `eks:CreateCluster` to the policy and reattach

**Error**: `NotAuthorizedException: User is not authorized to perform: iam:CreateRole`
- **Fix**: Add `iam:CreateRole` and IAM management permissions

**Error**: `UnauthorizedOperation: The authorization header is malformed`
- **Fix**: Check AWS credentials: `aws sts get-caller-identity`

## Security Best Practices

1. **Use Terraform Cloud/State File Encryption**: Don't store sensitive data in terraform.tfstate
2. **Enable MFA**: Require MFA for user running Terraform
3. **Use IAM Identity Center**: Instead of long-lived access keys
4. **Rotate Access Keys**: Every 90 days
5. **Audit Terraform Actions**: Enable CloudTrail logging
6. **Use Least Privilege**: Start with this policy, add permissions as needed
7. **Separate Environments**: Use different users for dev/prod

## AWS Organizations / Account Isolation

If using AWS Organizations:

Add an additional permission boundary to restrict regions:

```json
{
  "Sid": "AllowSpecificRegion",
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "aws:RequestedRegion": "ap-southeast-1"
    }
  }
}
```

## Multi-Account Setup

For deploying to a different AWS account:

1. User assumes a role in the target account
2. Target account role has the EKS permissions
3. User's account role has permission to assume target role

```bash
# Assume role in target account
aws sts assume-role \
  --role-arn arn:aws:iam::TARGET_ACCOUNT_ID:role/TerraformRole \
  --role-session-name terraform-session
```

## Next Steps

1. Create the IAM policy with your AWS account ID
2. Attach to your user
3. Verify: `terraform plan`
4. Deploy: `terraform apply`

For questions about specific permissions, refer to the [AWS IAM Documentation](https://docs.aws.amazon.com/iam/latest/UserGuide/) and [EKS API Reference](https://docs.aws.amazon.com/eks/latest/userguide/accessing-the-api.html).
