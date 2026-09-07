# ---------------------------------------
# Input Variables for Existing Resources
# ---------------------------------------
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of an existing public subnet"
  type        = string
}

variable "instance_type" {
  description = "Hardware instance type"
  type        = string
}

variable "ami" {
  description = "OS image"
  type        = string
}

variable "ec2_count" {
  description = "Number of ec2 hosts"
  type        = number
}

variable "key_name" {
  description = "Name of an existing EC2 key pair (optional, for SSH)"
  type        = string
  default     = null
}

variable "enable_ipv4" {
  description = "Enable IPv4 for the EC2 hosts"
  type        = bool
}

variable "task_image" {
  description = "Image for the task"
  type        = string
}

variable "efs_id" {
  description = "EFS ID"
  type        = string
}

variable "service_count" {
  description = "Number of container replicas"
  type        = number
}