terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_database_cluster" "this" {
  name                  = var.name
  engine                = "pg"
  size                  = var.size
  region                = var.region
  node_count            = var.node_count
  version               = var.pg_version
  tags                  = var.tags
  private_network_uuid  = var.private_network_uuid
  #project_id            = var.project_id        
  storage_size_mib      = var.storage_size_mib       
}

resource "digitalocean_database_firewall" "this" {
  cluster_id = digitalocean_database_cluster.this.id
  dynamic "rule" {
    for_each = var.firewall_rules
    content {
      type  = rule.value["type"]
      value = rule.value["value"]
    }
  }
}
