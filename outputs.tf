# Exposes the key root-level outputs needed for verification and for later modules.
# These outputs make the network foundation visible without opening the state file directly.

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.network.private_subnet_ids
}

output "selected_azs" {
  description = "Availability Zones used for the deployment."
  value       = module.network.selected_azs
}