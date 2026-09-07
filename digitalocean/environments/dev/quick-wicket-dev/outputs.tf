output "node_public_ips" {
  value = <<EOT
  FE: ${digitalocean_droplet.droplet_fe.ipv4_address}
  BE: ${digitalocean_droplet.droplet_be.ipv4_address}
  DB: ${digitalocean_droplet.droplet_db.ipv4_address}
  OD: ${digitalocean_droplet.droplet_od.ipv4_address}
  MEM: ${digitalocean_droplet.droplet_mem.ipv4_address}
  EOT
}

output "node_private_ips" {
  value = <<EOT
  FE: ${digitalocean_droplet.droplet_fe.ipv4_address_private}
  BE: ${digitalocean_droplet.droplet_be.ipv4_address_private}
  DB: ${digitalocean_droplet.droplet_db.ipv4_address_private}
  OD: ${digitalocean_droplet.droplet_od.ipv4_address_private}
  MEM: ${digitalocean_droplet.droplet_mem.ipv4_address_private}
  EOT
}