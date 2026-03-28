# Exposes the key root-level outputs needed for verification and for later modules.
# These outputs make the network foundation visible without opening the state file directly.

# -----------------------------------------------------------------------------
# Network outputs
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Database outputs
# -----------------------------------------------------------------------------

output "db_endpoint" {
  description = "Endpoint address of the database instance."
  value       = module.database.db_endpoint
}

output "db_port" {
  description = "Database port."
  value       = module.database.db_port
}

output "db_security_group_id" {
  description = "Security group ID attached to the database instance."
  value       = module.database.db_security_group_id
}

# -----------------------------------------------------------------------------
# Web / load balancer outputs
# -----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = module.web.alb_dns_name
}

output "asg_name" {
  description = "Name of the web tier Auto Scaling Group."
  value       = module.web.asg_name
}

output "web_security_group_id" {
  description = "Security group ID attached to the web instances."
  value       = module.web.web_security_group_id
}

# -----------------------------------------------------------------------------
# Bastion outputs
# -----------------------------------------------------------------------------

output "bastion_public_ip" {
  description = "Public IP address of the bastion host."
  value       = module.bastion.bastion_public_ip
}

output "bastion_security_group_id" {
  description = "Security group ID attached to the bastion host."
  value       = module.bastion.bastion_security_group_id
}