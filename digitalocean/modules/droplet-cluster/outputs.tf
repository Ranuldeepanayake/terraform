output "node_public_ips" {
  value = <<EOT
  Node-1: ${digitalocean_droplet.droplet_1.ipv4_address}
  Node-2: ${digitalocean_droplet.droplet_2.ipv4_address}
  Node-3: ${digitalocean_droplet.droplet_3.ipv4_address}
  EOT
}

output "node_private_ips" {
  value = <<EOT
  Node-1: ${digitalocean_droplet.droplet_1.ipv4_address_private}
  Node-2: ${digitalocean_droplet.droplet_2.ipv4_address_private}
  Node-3: ${digitalocean_droplet.droplet_3.ipv4_address_private}
  EOT
}