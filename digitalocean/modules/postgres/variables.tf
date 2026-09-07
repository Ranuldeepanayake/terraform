variable "name" {
  description = "The name of the database cluster."
  type        = string
}

variable "size" {
  description = "The size/slug of the database cluster."
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "region" {
  description = "The region to create the database in."
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the database cluster"
  type        = string
  default     = "1"
}

variable "pg_version" {
  description = "The version of Postgres."
  type        = string
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "private_network_uuid" {
  description = "The VPC UUID to launch the database in."
  type        = string
  default     = null
}

variable "firewall_rules" {
  description = "A list of firewall rules for the database cluster."
  type = list(object({
    type  = string
    value = string
  }))
  default = []
}

variable "storage_size_mib" {
  description = "Database storage size in MiB. Minimum is 10240 (10GB)."
  type        = string
  default     = "10"
}
