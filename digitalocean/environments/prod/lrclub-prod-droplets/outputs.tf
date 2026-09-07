output "node_public_ips" {
  value = <<EOT
  Node-1: ${digitalocean_droplet.droplet_fe.ipv4_address}
  Node-2: ${digitalocean_droplet.droplet_be.ipv4_address}
  Node-3: ${digitalocean_droplet.droplet_od.ipv4_address}
  Node-4: ${digitalocean_droplet.droplet_db_primary.ipv4_address}
  Node-5: ${digitalocean_droplet.droplet_db_replica.ipv4_address}
  EOT
}

output "node_private_ips" {
  value = <<EOT
  Node-1: ${digitalocean_droplet.droplet_fe.ipv4_address_private}
  Node-2: ${digitalocean_droplet.droplet_be.ipv4_address_private}
  Node-3: ${digitalocean_droplet.droplet_od.ipv4_address_private}
  Node-4: ${digitalocean_droplet.droplet_db_primary.ipv4_address_private}
  Node-5: ${digitalocean_droplet.droplet_db_replica.ipv4_address_private}
  EOT
}