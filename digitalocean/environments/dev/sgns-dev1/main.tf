terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.0"
    }
  }
}

#Digital ocean API token.
provider "digitalocean" {
  token = var.do_token
}

#Data source which includes all droplets.
data "digitalocean_droplets" "droplet" {}

#Filter datasource for droplets with a particular tag.
locals {
  tagged_droplets = {
    for d in data.digitalocean_droplets.droplet.droplets :
    d.id => d
    if contains(d.tags, var.tag_name)
  }
}

/*
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
    source_droplet_ids = []
  }
  inbound_rule {
    protocol   = "tcp"
    port_range = "5672"
    source_droplet_ids = []
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "9578"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol   = "tcp"
    port_range = "8080"
    source_droplet_ids = []
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
*/

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
*/

/*
#Disk usage alerts.
resource "digitalocean_monitor_alert" "disk_usage_alert" {
  for_each = local.tagged_droplets

  alerts {
    email = var.alert_email
  }

  window  = "5m"
  type    = "v1/insights/droplet/disk_utilization_percent"
  compare = "GreaterThan"
  value   = 80
  enabled = true

  entities    = [each.key]
  description = "Disk usage > 80% for 5 minutes"
}
*/

#Uptime check for the root domain.
resource "digitalocean_uptime_check" "fe_https" {
  name    = "sgns-dev1-https"
  target  = var.domain_name
  regions = ["us_east", "us_west", "eu_west", "se_asia"]
}

#Create a latency alert for the uptime check
resource "digitalocean_uptime_alert" "fe_https_downtime" {
  name     = "${digitalocean_uptime_check.fe_https.name}-downtime"
  check_id = digitalocean_uptime_check.fe_https.id
  type     = "down"
  period   = "2m"
  notifications {
    email = var.alert_email
  }
}