### Module which creates a route table and it's routes.
Keep in mind that NAT gateways only support IPv4 traffic. For IPv6 traffic, use an egress only internet gateway.

# Check existing resources.
aws ec2 describe-route-tables --query 'RouteTables[*].{ID:RouteTableId,VPC:VpcId,Routes:Routes,Associations:Associations,Tags:Tags}' --output table
aws ec2 describe-route-tables --query 'RouteTables[*].{RouteTableId:RouteTableId,VpcId:VpcId}' --output table
aws ec2 describe-route-tables --query 'RouteTables[*].Routes[*].{Destination:(DestinationCidrBlock || DestinationIpv6CidrBlock ||
DestinationPrefixListId),Gateway:GatewayId,NAT:NatGatewayId,TransitGateway:TransitGatewayId,State:State}' --route-table-ids rtb-0547691a78a0a42b6 --output table
aws ec2 describe-route-tables --route-table-ids rtb-0123456789abcdef0
## Import existing resources into terraform
terraform import 'module.route_table.aws_route_table.this' rtb-0123456789abcdef0
terraform import 'module.route_table.aws_route.this["internet"]' 'rtb-0123456789abcdef0_0.0.0.0/0'

## Caller examples

# Public route table
{
    vpc_id = "vpc-0123456789abcdef0"
    route_table_name = "public-route-table"

    routes = [
        {
            cidr_block = "0.0.0.0/0"
            gateway_id = "igw-0123456789abcdef0"
        }
    ]

    tags = {
        Environment = "dev"
        Project     = "my-project"
        ManagedBy   = "Terraform"
    }
}

# Private route table
{
    vpc_id = "vpc-0123456789abcdef0"

    route_table_name = "private-route-table"

    routes = [
        {
            cidr_block      = "0.0.0.0/0"
            nat_gateway_id  = "nat-0123456789abcdef0"
        },
        {
            ipv6_cidr_block = "::/0"
            gateway_id      = "igw-0123456789abcdef0"
        },
        {
            cidr_block          = "10.20.0.0/16"
            transit_gateway_id  = "tgw-0123456789abcdef0"
        }
    ]

    tags = {
        Environment = "dev"
        Project     = "my-project"
        ManagedBy   = "Terraform"
    }
}