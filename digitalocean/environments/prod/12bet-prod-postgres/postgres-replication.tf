terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_vpc" "vpc" {
  name = "default-blr1"
}

resource "digitalocean_droplet" "pg_node_primary" {
  image      = var.pg_node_image
  name       = "${var.pg_cluster_name}-db-primary"
  region     = var.region
  size       = var.pg_node_size
  ipv6       = var.pg_node_ipv6
  monitoring = var.pg_node_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.pg_node_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-postgres-1.yaml", {
    cluster_name = var.pg_cluster_name
    node_prefix  = var.pg_node_prefix
    domain       = var.domain
  })

  tags              = var.pg_node_tags
  droplet_agent     = var.pg_node_agent
  graceful_shutdown = var.pg_node_graceful_shutdown
}

resource "digitalocean_droplet" "pg_node_replica" {
  image      = var.pg_node_image
  name       = "${var.pg_cluster_name}-db-replica"
  region     = var.region
  size       = var.pg_node_size
  ipv6       = var.pg_node_ipv6
  monitoring = var.pg_node_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.pg_node_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-postgres-2.yaml", {
    cluster_name = var.pg_cluster_name
    node_prefix  = var.pg_node_prefix
    domain       = var.domain
  })

  tags              = var.pg_node_tags
  droplet_agent     = var.pg_node_agent
  graceful_shutdown = var.pg_node_graceful_shutdown

  depends_on = [
    digitalocean_droplet.pg_node_primary
  ]
}

resource "digitalocean_droplet" "pg_node_reporting" {
  image      = var.pg_node_image
  name       = "${var.pg_cluster_name}-db-reporting"
  region     = var.region
  size       = var.pg_node_size
  ipv6       = var.pg_node_ipv6
  monitoring = var.pg_node_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.pg_node_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-postgres-reporting.yaml", {
    cluster_name = var.pg_cluster_name
    node_prefix  = var.pg_node_prefix
    domain       = var.domain
  })

  tags              = var.pg_node_tags
  droplet_agent     = var.pg_node_agent
  graceful_shutdown = var.pg_node_graceful_shutdown

  depends_on = [
    digitalocean_droplet.pg_node_replica
  ]
}