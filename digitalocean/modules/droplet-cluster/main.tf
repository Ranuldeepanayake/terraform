terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

/*
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "sgn-digitalocean-droplet-cluster-test"
    }
  }
*/
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_vpc" "vpc" {
  name = "default-blr1"
}

/*
resource "digitalocean_vpc" "droplet_vpc" {
  name     = "postgres-vpc"
  region   = var.region
  ip_range = "10.0.1.0/24"
}
*/

resource "digitalocean_droplet" "droplet_1" {
  image      = var.droplet_image
  name       = "${var.droplet_prefix}-1"
  region     = var.region
  size       = var.droplet_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet.yaml", {
    cluster_name = var.droplet_cluster_name
    node_prefix  = var.droplet_prefix
    domain       = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown
}

resource "digitalocean_droplet" "droplet_2" {
  image      = var.droplet_image
  name       = "${var.droplet_prefix}-2"
  region     = var.region
  size       = var.droplet_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet.yaml", {
    cluster_name = var.droplet_cluster_name
    node_prefix  = var.droplet_prefix
    domain       = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_1
  ]
}

resource "digitalocean_droplet" "droplet_3" {
  image      = var.droplet_image
  name       = "${var.droplet_prefix}-3"
  region     = var.region
  size       = var.droplet_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet.yaml", {
    cluster_name = var.droplet_cluster_name
    node_prefix  = var.droplet_prefix
    domain       = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_2
  ]
}

#Firewall.
resource "digitalocean_firewall" "common_firewall" {
  name = var.droplet_cluster_name

  #Attach to droplets created later via droplet_ids.
  droplet_ids = [digitalocean_droplet.droplet_1.id, digitalocean_droplet.droplet_2.id, digitalocean_droplet.droplet_3.id]

  #Inbound rules.
  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
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