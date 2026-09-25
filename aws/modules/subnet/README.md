### Module which creates a subnet and it's route table association.
Keep in mind that IPv6 addresses set for a subnet are publicly routable and the subnet mask be between /56 - /64.

# Check existing resources.
aws ec2 describe-subnets --filters Name=vpc-id,Values="vpc-02ae59b36d4cf20d7" --query \
'Subnets[*].[SubnetId,CidrBlock,Ipv6CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' --output table
aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-02ae59b36d4cf20d7 Name=cidr-block,Values=10.0.1.0/24 --query 'Subnets[0].[SubnetId,CidrBlock]' --output text
aws ec2 describe-route-tables --route-table-ids "rtb-02c923a5f28e88df3" --query 'RouteTables[0].Associations[*].[AssociationId,SubnetId,RouteTableId,Main]' --output table
## Import existing resources into terraform
terraform import 'module.subnet.aws_subnet.subnet["a"]' 'subnet-089b9610c4dee02f4'
terraform import 'module.subnet.aws_route_table_association.rta["a"]' 'subnet-089b9610c4dee02f4/rtb-02c923a5f28e88df3'

