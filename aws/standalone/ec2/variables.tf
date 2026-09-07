# ---------------------------------------
# Input Variables for Existing Resources
# ---------------------------------------
variable "resource_name" {
  description = "A name to easily identify a resource"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

#variable "availability_zone" {
#  description = "ID of the availability zone"
#  type        = string
#}

variable "subnet_id" {
  description = "ID of an existing public subnet"
  type        = string
}

variable "instance_type" {
  description = "Hardware instance type"
  type        = string
}

variable "ami" {
  description = "OS image AMI"
  type        = string
}

#variable "ec2_count" {
#  description = "Number of ec2 hosts"
#  type        = number
#}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH"
  type        = string
  default     = null
}

variable "enable_ipv4" {
  description = "Enable IPv4 for the EC2 hosts"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags for the resource"
  type        = map(string)
  default = {
    resource-type = "ec2"
    purpose       = "general-purpose"
  }
}