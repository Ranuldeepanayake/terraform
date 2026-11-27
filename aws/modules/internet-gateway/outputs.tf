output "id" {
  description = "Internet gateway ID"
  value       = aws_internet_gateway.this.id
}

output "arn" {
  description = "ARN of the internet gateway."
  value       = aws_internet_gateway.this.arn
}

output "vpc_id" {
  description = "ID of the VPC attached to the internet gateway."
  value       = aws_internet_gateway.this.vpc_id
}

output "owner_id" {
  description = "AWS account ID that owns the internet gateway."
  value       = aws_internet_gateway.this.owner_id
}

output "tags" {
  description = "Tags applied to the internet gateway."
  value       = aws_internet_gateway.this.tags
}