terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  #cloud {
  #  organization = "ranuldeepanayake"
  #  workspaces {
  #    name = "digitalocean-dev-jump-host"
  #  }

  #}
}

#Provider authentication.
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_vpc" "vpc" {
  name = "blr1-vpc-01"
}

data "digitalocean_ssh_key" "key_1" {
  name = "ranul@ranger-pc"
}

#resource "digitalocean_ssh_key" "new_key" {
#  name       = "ci-server-key"
#  public_key = file("~/.ssh/ci-server.pub")
#}

module "droplet" {
  source     = "../../../modules/droplet"
  image      = "ubuntu-24-04-x64"
  name       = "jump-host-1"
  region     = "blr1"
  size       = "s-1vcpu-512mb-10gb"
  ipv6       = true
  monitoring = true
  vpc_uuid   = data.digitalocean_vpc.vpc.id
  #ssh_keys           = var.ssh_keys
  ssh_keys = [data.digitalocean_ssh_key.key_1.id, "d5:6a:b7:c6:1f:05:57:dc:38:ca:ea:30:44:a7:59:94"]

  user_data = fileexists("${path.module}/cloud-init.yaml") ? templatefile("${path.module}/cloud-init.yaml",
  { docker_user = "ubuntu" }) : null

  tags              = ["droplet", "linux", "jump-host"]
  droplet_agent     = true
  graceful_shutdown = true
}