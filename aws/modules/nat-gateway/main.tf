# Elastic IP used by the public NAT Gateway. A public NAT Gateway requires an Elastic IP address.
# The EIP provides the public IPv4 address through which private subnet resources access the internet.
resource "aws_eip" "this" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name         = "${var.name}"
      ResourceType = "elastic-ip"
    }
  )
}

# NAT Gateway. The NAT Gateway must be placed in a PUBLIC subnet.
# The public subnet should have:
#   1. A route to an Internet Gateway.
#   2. The NAT Gateway's Elastic IP attached to it.
# Private subnets can then route their internet-bound traffic (0.0.0.0/0) to this NAT Gateway.
resource "aws_nat_gateway" "this" {
  allocation_id     = aws_eip.this.id
  subnet_id         = var.subnet_id
  connectivity_type = var.connectivity_type

  tags = merge(
    var.tags,
    {
      Name         = "${var.name}"
      ResourceType = "nat-gateway"
    }
  )

  # Check if there is an interenet gateway to support the NAT gateway.
  depends_on = [
    data.aws_internet_gateway.this
  ]
}