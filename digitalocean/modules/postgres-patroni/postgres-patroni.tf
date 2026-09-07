terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "digitalocean-postgres-cluster"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_vpc" "pg_vpc" {
  name     = "postgres-vpc"
  region   = var.region
  ip_range = "10.0.1.0/24"
}

resource "digitalocean_droplet" "pg_node_1" {
  image      = var.pg_node_image
  name       = "${var.pg_node_prefix}-1"
  region     = var.region
  size       = var.pg_node_size
  ipv6       = var.pg_node_ipv6
  monitoring = var.pg_node_monitoring
  vpc_uuid   = digitalocean_vpc.pg_vpc.id
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

resource "digitalocean_droplet" "pg_node_2" {
  image      = var.pg_node_image
  name       = "${var.pg_node_prefix}-2"
  region     = var.region
  size       = var.pg_node_size
  ipv6       = var.pg_node_ipv6
  monitoring = var.pg_node_monitoring
  vpc_uuid   = digitalocean_vpc.pg_vpc.id
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
    digitalocean_droplet.pg_node_1
  ]
}

/*
resource "digitalocean_droplet" "pg_node_3" {
  image      = var.pg_node_image
  name       = "${var.pg_node_prefix}-3"
  region     = var.region
  size       = var.pg_node_size
  ipv6       = var.pg_node_ipv6
  monitoring = var.pg_node_monitoring
  vpc_uuid   = digitalocean_vpc.pg_vpc.id
  ssh_keys   = var.pg_node_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-postgres-3.yaml", {
    cluster_name = var.pg_cluster_name
    node_prefix  = var.pg_node_prefix
    domain       = var.domain
  })

  tags              = var.pg_node_tags
  droplet_agent     = var.pg_node_agent
  graceful_shutdown = var.pg_node_graceful_shutdown

  depends_on = [
    digitalocean_droplet.pg_node_2
  ]
}
*/

#HA proxy droplet.
resource "digitalocean_droplet" "haproxy" {
  name       = var.ha_proxy_name
  image      = var.ha_proxy_image
  region     = var.region
  size       = var.ha_proxy_size
  ipv6       = var.ha_proxy_ipv6
  monitoring = var.ha_proxy_monitoring
  vpc_uuid   = digitalocean_vpc.pg_vpc.id
  ssh_keys   = var.ha_proxy_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-ha-proxy.yaml", {
    pg1 = digitalocean_droplet.pg_node_1.ipv4_address_private
    pg2 = digitalocean_droplet.pg_node_2.ipv4_address_private
  })

  tags              = var.ha_proxy_tags
  droplet_agent     = var.ha_proxy_agent
  graceful_shutdown = var.ha_proxy_graceful_shutdown

  depends_on = [digitalocean_droplet.pg_node_1, digitalocean_droplet.pg_node_2]
}

#Firewall.
resource "digitalocean_firewall" "postgres_firewall" {
  name = var.pg_cluster_name

  # Attach to droplets created later via droplet_ids
  droplet_ids = [digitalocean_droplet.pg_node_1.id, digitalocean_droplet.pg_node_2.id]

  #Inbound rules.
  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["10.0.0.0/16"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["10.0.1.0/24"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "5432"
    source_addresses = ["10.0.1.0/24"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "2379-2380"
    source_addresses = ["10.0.1.0/24"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8008"
    source_addresses = ["10.0.1.0/24"]
  }

  #Outbound rules.
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}