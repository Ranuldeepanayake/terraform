#Common variables.
variable "do_token" {
  type      = string
  sensitive = true
}

variable "droplet_cluster_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "region" {
  type = string
}

variable "project_id" {
  type = string
}

#Droplet node variables.
variable "droplet_image" {
  type = string
}

variable "droplet_ipv6" {
  type = bool
}

variable "droplet_monitoring" {
  type = bool
}

variable "droplet_ssh_keys" {
  type = list(string)
}

variable "droplet_tags" {
  type    = list(string)
  default = []
}

variable "droplet_agent" {
  type = bool
}

variable "droplet_graceful_shutdown" {
  type = bool
}

variable "droplet_fe_size" {
  type = string
}

variable "droplet_be_size" {
  type = string
}

variable "droplet_db_size" {
  type = string
}

variable "droplet_od_size" {
  type = string
}

variable "droplet_mem_size" {
  type = string
}