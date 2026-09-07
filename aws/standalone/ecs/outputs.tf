output "instance_id" {
  value = aws_instance.ecs_instance.id
}

output "private_ip" {
  value = aws_instance.ecs_instance.private_ip
}

output "private_dns" {
  value = aws_instance.ecs_instance.private_dns
}

output "public_ip" {
  value = aws_instance.ecs_instance.public_ip
}

output "public_dns" {
  value = aws_instance.ecs_instance.public_dns
}

output "ipv6_addresses" {
  value = aws_instance.ecs_instance.ipv6_addresses
}

output "availability_zone" {
  value = aws_instance.ecs_instance.availability_zone
}