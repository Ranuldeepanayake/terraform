output "instance_id" {
  value = aws_instance.ec2.id
}

output "private_ip" {
  value = aws_instance.ec2.private_ip
}

output "private_dns" {
  value = aws_instance.ec2.private_dns
}

output "public_ip" {
  value = aws_instance.ec2.public_ip
}

output "public_dns" {
  value = aws_instance.ec2.public_dns
}

output "ipv6_addresses" {
  value = aws_instance.ec2.ipv6_addresses
}

output "availability_zone" {
  value = aws_instance.ec2.availability_zone
}