output "node_public_ips" {
  value = <<EOT
  Node-1: ${digitalocean_droplet.pg_node_primary.ipv4_address}
  Node-2: ${digitalocean_droplet.pg_node_replica.ipv4_address}
  Node-3: ${digitalocean_droplet.pg_node_reporting.ipv4_address}
  EOT
}

output "node_private_ips" {
  value = <<EOT
  Node-1: ${digitalocean_droplet.pg_node_primary.ipv4_address_private}
  Node-2: ${digitalocean_droplet.pg_node_replica.ipv4_address_private}
  Node-3: ${digitalocean_droplet.pg_node_reporting.ipv4_address_private}
  EOT
}