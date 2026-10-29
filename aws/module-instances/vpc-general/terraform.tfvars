aws_region                       = "ap-southeast-1"
name                             = "singapore-1"
cidr_block                       = "10.0.0.0/16"
enable_dns_support               = true
enable_dns_hostnames             = true
assign_generated_ipv6_cidr_block = true

tags = {
    Environment      = "dev"
    ResourceCategory = "vpc"
    ManagedBy        = "terraform"
  }