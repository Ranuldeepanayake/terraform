#Common variables.
variable "do_token" {
  type      = string
  sensitive = true
}

variable "pg_cluster_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "region" {
  type = string
}

#Postgres node variables.
variable "pg_node_image" {
  type = string
}

variable "pg_node_prefix" {
  type = string
}

variable "pg_node_size" {
  type = string
}

variable "pg_node_ipv6" {
  type = bool
}

variable "pg_node_monitoring" {
  type = bool
}

variable "pg_node_ssh_keys" {
  type = list(string)
}

variable "pg_node_tags" {
  type    = list(string)
  default = []
}

variable "pg_node_agent" {
  type = bool
}

variable "pg_node_graceful_shutdown" {
  type = bool
}