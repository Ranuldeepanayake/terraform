output "id" {
  description = "Internet gateway ID"
  value       = module.internet_gateway.id
}

output "arn" {
  description = "Internet gateway ARN"
  value       = module.internet_gateway.arn
}

output "vpc_id" {
  description = "ID of the VPC attached to the internet gateway"
  value       = module.internet_gateway.vpc_id
}

output "owner_id" {
  description = "AWS account ID that owns the internet gateway"
  value       = module.internet_gateway.owner_id
}

output "tags" {
  description = "Tags applied to the internet gateway"
  value       = module.internet_gateway.tags
}