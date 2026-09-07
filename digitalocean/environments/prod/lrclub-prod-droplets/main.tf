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
  name = "sfo3-vpc-01"
}

#FE droplet.
resource "digitalocean_droplet" "droplet_fe" {
  image      = var.droplet_image
  name       = "${var.droplet_prefix}-fe"
  region     = var.region
  size       = var.droplet_fe_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet-fe.yaml", {
    droplet_prefix = var.droplet_prefix
    domain         = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown
}

#BE droplet.
resource "digitalocean_droplet" "droplet_be" {
  image      = var.droplet_image
  name       = "${var.droplet_prefix}-be"
  region     = var.region
  size       = var.droplet_be_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet-be.yaml", {
    droplet_prefix = var.droplet_prefix
    domain         = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_fe
  ]
}

#OD droplet.
resource "digitalocean_droplet" "droplet_od" {
  image      = var.droplet_image
  name       = "${var.droplet_prefix}-od"
  region     = var.region
  size       = var.droplet_od_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet-od.yaml", {
    droplet_prefix = var.droplet_prefix
    domain         = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_be
  ]
}

resource "digitalocean_droplet" "droplet_db_primary" {
  image      = var.droplet_image
  name       = "${var.droplet_prefix}-db-primary"
  region     = var.region
  size       = var.droplet_db_primary_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-postgres-1.yaml", {
    cluster_name   = var.droplet_cluster_name
    droplet_prefix = var.droplet_prefix
    domain         = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_od
  ]
}

resource "digitalocean_droplet" "droplet_db_replica" {
  image      = var.droplet_image
  name       = "${var.droplet_cluster_name}-db-replica"
  region     = var.region
  size       = var.droplet_db_replica_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-postgres-2.yaml", {
    cluster_name   = var.droplet_cluster_name
    droplet_prefix = var.droplet_prefix
    domain         = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_db_primary
  ]
}

#Assign droplets to a project.
resource "digitalocean_project_resources" "project" {
  project = var.project_id
  resources = [digitalocean_droplet.droplet_fe.urn, digitalocean_droplet.droplet_be.urn, digitalocean_droplet.droplet_od.urn,
  digitalocean_droplet.droplet_db_primary.urn, digitalocean_droplet.droplet_db_replica.urn]
}

#Firewall.
resource "digitalocean_firewall" "common_firewall" {
  name = var.droplet_cluster_name

  #Attach to droplets created later via droplet_ids.
  droplet_ids = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_od.id,
  digitalocean_droplet.droplet_db_primary.id, digitalocean_droplet.droplet_db_replica.id]

  #Inbound rules.
  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "3800"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "5672"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "9578"
    source_addresses = ["0.0.0.0/0", "::/0"]
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

/*
#CPU alerts.
resource "digitalocean_monitor_alert" "cpu_alert" {
  alerts {
    email = ["ranuldeepanayake@outlook.com"]
  }

  window  = "5m"
  type    = "v1/insights/droplet/cpu"
  compare = "GreaterThan"
  value   = 70
  enabled = true

  entities    = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_od.id]
  description = "CPU usage > 70% for 5 minutes"
}
*/