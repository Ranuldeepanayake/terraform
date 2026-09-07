output "node_public_ips" {
  value = <<EOT
  Node-1: ${digitalocean_droplet.pg_node_1.ipv4_address}
  Node-2: ${digitalocean_droplet.pg_node_2.ipv4_address}
  EOT
}

output "node_private_ips" {
  value = <<EOT
  Node-1: ${digitalocean_droplet.pg_node_1.ipv4_address_private}
  Node-2: ${digitalocean_droplet.pg_node_2.ipv4_address_private}
  EOT
}

output "haproxy_public_ip" {
  value = digitalocean_droplet.haproxy.ipv4_address
}

output "haproxy_private_ip" {
  value = digitalocean_droplet.haproxy.ipv4_address_private
}