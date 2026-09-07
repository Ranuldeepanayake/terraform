resource "digitalocean_monitor_alert" "cpu_alert" {
  alerts {
    email = ["your@email.com"]
  }

  #Slack webhook (optional).
  alerts {
    slack {
      url     = var.slack_webhook
      channel = "#alerts"
    }
  }

  window      = "5m"
  type        = "v1/insights/droplet/cpu"
  compare     = "GreaterThan"
  value       = 80
  enabled     = true

  entities = [
    digitalocean_droplet.web.id
  ]
  
  #Apply to all existing droplets.
  #entities = data.digitalocean_droplets.all.ids

  description = "Alert when CPU usage > 80% for 5 minutes"
}

resource "digitalocean_monitor_alert" "memory_alert" {
  alerts {
    email = ["your@email.com"]
  }

  window      = "5m"
  type        = "v1/insights/droplet/memory_utilization_percent"
  compare     = "GreaterThan"
  value       = 75
  enabled     = true

  entities = [
    digitalocean_droplet.web.id
  ]

  description = "Alert when memory usage > 75%"
}

resource "digitalocean_monitor_alert" "offline_alert" {
  alerts {
    email = ["your@email.com"]
  }

  window      = "5m"
  type        = "v1/insights/droplet/droplet_status"
  compare     = "GreaterThan"
  value       = 0
  enabled     = true

  entities = [
    digitalocean_droplet.web.id
  ]

  description = "Alert when droplet is offline"
}

#To apply to all droplets.
data "digitalocean_droplets" "all" {
  tag = "production"
}

