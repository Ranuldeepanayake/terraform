variable "vpc_id" {}

variable "subnet_id" {}

variable "security_group_name" {
    type = string
    description = "Name to be appended to the security group"
    default = "security-group-for-subnet"
}