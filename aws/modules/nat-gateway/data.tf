# Data source to get the internet gateway associated with this NAT gateway.
data "aws_internet_gateway" "this" {
  internet_gateway_id = var.internet_gateway_id
}