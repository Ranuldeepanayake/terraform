terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_droplet" "this" {
  image             = var.image
  name              = var.name
  region            = var.region
  size              = var.size
  ipv6              = var.ipv6
  monitoring        = var.monitoring
  vpc_uuid          = var.vpc_uuid
  ssh_keys          = var.ssh_keys
  #user_data         = var.user_data_template != null ? templatefile(var.user_data_template, {docker_user = var.docker_user}) : null
  user_data         = var.user_data
  tags              = var.tags
  droplet_agent     = var.droplet_agent
  graceful_shutdown = var.graceful_shutdown
}
