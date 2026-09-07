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
      name = "digitalocean-dev-postgres-general"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_vpc" "vpc" {
  name = "blr1-vpc-02"
}

module "postgres" {
  source     = "../../../modules/postgres"
  name       = "db-postgresql-blr1-39303"
  size       = "db-s-1vcpu-1gb"
  region     = "blr1"
  node_count = "1"
  #'version' is a reserved keyword when using modules.
  pg_version           = "18"
  tags                 = ["database", "postgres"]
  private_network_uuid = data.digitalocean_vpc.vpc.id
  #project_id
  storage_size_mib = "10240"

  firewall_rules = [
    { type = "ip_addr", value = "0.0.0.0" }
  ]
}
