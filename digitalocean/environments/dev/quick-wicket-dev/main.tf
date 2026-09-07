terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

#Digital ocean API token.
provider "digitalocean" {
  token = var.do_token
}

#Use the already created VPC.
data "digitalocean_vpc" "vpc" {
  name = "sgp1-vpc-lr"
}

#FE droplet.
resource "digitalocean_droplet" "droplet_fe" {
  image      = var.droplet_image
  name       = "${var.droplet_cluster_name}-fe"
  region     = var.region
  size       = var.droplet_fe_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet-fe.yaml", {
    droplet_cluster_name = var.droplet_cluster_name
    domain               = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown
}

#BE droplet.
resource "digitalocean_droplet" "droplet_be" {
  image      = var.droplet_image
  name       = "${var.droplet_cluster_name}-be"
  region     = var.region
  size       = var.droplet_be_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet-be.yaml", {
    droplet_cluster_name = var.droplet_cluster_name
    domain               = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_fe
  ]
}

#DB droplet.
resource "digitalocean_droplet" "droplet_db" {
  image      = var.droplet_image
  name       = "${var.droplet_cluster_name}-db"
  region     = var.region
  size       = var.droplet_db_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet-db.yaml", {
    droplet_cluster_name = var.droplet_cluster_name
    domain               = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_be
  ]
}

#OD droplet.
resource "digitalocean_droplet" "droplet_od" {
  image      = var.droplet_image
  name       = "${var.droplet_cluster_name}-od"
  region     = var.region
  size       = var.droplet_od_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet-od.yaml", {
    droplet_cluster_name = var.droplet_cluster_name
    domain               = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_db
  ]
}

#MEM droplet.
resource "digitalocean_droplet" "droplet_mem" {
  image      = var.droplet_image
  name       = "${var.droplet_cluster_name}-mem"
  region     = var.region
  size       = var.droplet_mem_size
  ipv6       = var.droplet_ipv6
  monitoring = var.droplet_monitoring
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  ssh_keys   = var.droplet_ssh_keys

  user_data = templatefile("${path.module}/cloud-init-droplet-mem.yaml", {
    droplet_cluster_name = var.droplet_cluster_name
    domain               = var.domain
  })

  tags              = var.droplet_tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.droplet_graceful_shutdown

  depends_on = [
    digitalocean_droplet.droplet_be
  ]
}

#Assign droplets to a project.
resource "digitalocean_project_resources" "project" {
  project = var.project_id
  resources = [digitalocean_droplet.droplet_fe.urn, digitalocean_droplet.droplet_be.urn, digitalocean_droplet.droplet_db.urn,
  digitalocean_droplet.droplet_od.urn, digitalocean_droplet.droplet_mem.urn]
}

#Firewall.
resource "digitalocean_firewall" "firewall" {
  name = var.droplet_cluster_name

  #Attach to droplets created via droplet_ids.
  droplet_ids = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_db.id,
  digitalocean_droplet.droplet_od.id, digitalocean_droplet.droplet_mem.id]

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
    protocol   = "tcp"
    port_range = "3800"
    source_droplet_ids = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_db.id,
    digitalocean_droplet.droplet_od.id, digitalocean_droplet.droplet_mem.id]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "5432"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol   = "tcp"
    port_range = "5672"
    source_droplet_ids = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_db.id,
    digitalocean_droplet.droplet_od.id, digitalocean_droplet.droplet_mem.id]
  }
  inbound_rule {
    protocol   = "tcp"
    port_range = "8080"
    source_droplet_ids = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_db.id,
    digitalocean_droplet.droplet_od.id, digitalocean_droplet.droplet_mem.id]
  }
  inbound_rule {
    protocol   = "tcp"
    port_range = "9191"
    source_droplet_ids = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_db.id,
    digitalocean_droplet.droplet_od.id, digitalocean_droplet.droplet_mem.id]
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
#CPU usage alerts.
resource "digitalocean_monitor_alert" "cpu_usage_alert" {
  alerts {
    email = ["ranul@esocialgames.net"]
  }

  window  = "5m"
  type    = "v1/insights/droplet/cpu"
  compare = "GreaterThan"
  value   = 80
  enabled = true

  entities = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_db.id,
  digitalocean_droplet.droplet_od.id, digitalocean_droplet.droplet_mem.id]
  description = "CPU usage > 80% for 5 minutes"
}

#Memory usage alerts.
resource "digitalocean_monitor_alert" "memory_usage_alert" {
  alerts {
    email = ["ranul@esocialgames.net"]
  }

  window  = "5m"
  type    = "v1/insights/droplet/memory_utilization_percent"
  compare = "GreaterThan"
  value   = 80
  enabled = true

  entities = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_db.id,
  digitalocean_droplet.droplet_od.id, digitalocean_droplet.droplet_mem.id]
  description = "Memory usage > 80% for 5 minutes"
}

#Disk usage alerts.
resource "digitalocean_monitor_alert" "disk_usage_alert" {
  alerts {
    email = ["ranul@esocialgames.net"]
  }

  window  = "5m"
  type    = "v1/insights/droplet/disk_utilization_percent"
  compare = "GreaterThan"
  value   = 80
  enabled = true

  entities = [digitalocean_droplet.droplet_fe.id, digitalocean_droplet.droplet_be.id, digitalocean_droplet.droplet_db.id,
  digitalocean_droplet.droplet_od.id, digitalocean_droplet.droplet_mem.id]
  description = "Disk usage > 80% for 5 minutes"
}

#Uptime check for the root domain.
resource "digitalocean_uptime_check" "fe_https" {
  name    = "${digitalocean_droplet.droplet_fe.name}-https"
  target  = "https://www.mydomain.com"
  regions = ["us_east", "us_west", "eu_west", "se_asia"]
}

# Create a latency alert for the uptime check
resource "digitalocean_uptime_alert" "fe_https_downtime" {
  name     = "${digitalocean_uptime_check.fe_https.name}-downtime"
  check_id = digitalocean_uptime_check.fe_https.id
  type     = "down"
  period   = "2m"
  notifications {
    email = ["ranul@esocialgames.net"]
  }
}
*/