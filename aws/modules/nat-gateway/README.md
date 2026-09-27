### Module which creates a NAT gateway.
- Keep in mind that NAT gateways only support IPv4 traffic. For IPv6 traffic, use an egress only internet gateway.
- Ensure an Internet Gateway exists before creating the NAT Gateway.

# Check existing resources.
aws ec2 describe-nat-gateways --query 'NatGateways[*].[NatGatewayId,State,VpcId,SubnetId,ConnectivityType,PublicIp]' --output table
aws ec2 describe-nat-gateways --filter Name=tag:Name,Values=my-nat-gateway --region ap-southeast-1 \
--query 'NatGateways[*].[NatGatewayId,AllocationId,SubnetId,ConnectivityType,State]' --output table
aws ec2 describe-nat-gateways --nat-gateway-ids nat-xxxxxxxx
## Import existing resources into terraform
terraform import 'module.nat_gateway.aws_eip.this' 'eipalloc-xxxxxxxxxxxxxxxxx'
terraform import 'module.nat_gateway.aws_nat_gateway.this' 'nat-xxxxxxxxxxxxxxxxx'