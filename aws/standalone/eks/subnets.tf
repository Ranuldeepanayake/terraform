#Reference an existing VPC.
data "aws_vpc" "existing" {
  id = var.vpc_id
}

#Reference an existing Internet Gateway.
data "aws_internet_gateway" "existing" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# Private Subnets for worker nodes
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = var.vpc_id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      ResourceType                                = "subnet"
      Exposure                                    = "private"
      Name                                        = "${var.cluster_name}-private-subnet-${count.index + 1}"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    }
  )
}

# Public Subnets for NAT Gateway and ELB/NLB
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      ResourceType                                = "subnet"
      Exposure                                    = "public"
      Name                                        = "${var.cluster_name}-public-subnet-${count.index + 1}"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      ResourceType = "elastic-ip"
      Name         = "${var.cluster_name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [data.aws_internet_gateway.existing]
}

# NAT Gateways in public subnets
resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      ResourceType = "nat-gateway"
      Name         = "${var.cluster_name}-nat-gateway-${count.index + 1}"
    }
  )

  depends_on = [data.aws_internet_gateway.existing]
}

# Route table for private subnets
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "route-table"
      Exposure     = "private"
    }
  )
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.existing.id
  }

  tags = merge(
    var.tags,
    {
      ResourceType = "route-table"
      Exposure     = "public"
    }
  )
}

# Association of private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Association of public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
