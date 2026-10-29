aws_region = "ap-southeast-1"

subnets = {
  a = {
    name                    = "subnet-a"
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "ap-southeast-1a"
    map_public_ip_on_launch = true
    tags                    = {
        az = "ap-southeast-1a"
    }
  }

  b = {
    name                    = "subnet-b"
    cidr_block              = "10.0.2.0/24"
    availability_zone       = "ap-southeast-1b"
    map_public_ip_on_launch = true
    tags                    = {
        az = "ap-southeast-1b"
    }
  }
}

destination_cidr_block = "0.0.0.0/16"

route_table_tags = {
    name = "route-table-1"
} 