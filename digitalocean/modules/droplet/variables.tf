variable "image" {
  type    = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "size" {
  type = string
}

variable "ipv6" {
  type = bool
}

variable "monitoring" {
  type = bool
}

variable "vpc_uuid" {
  type    = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "droplet_agent" {
  type = bool
}

variable "graceful_shutdown" {
  type = bool
}

variable "user_data" {
  description = "Contents of a cloud-init.yaml file."
  type        = string
  default     = null
}