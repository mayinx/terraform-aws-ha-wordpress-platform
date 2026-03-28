# Exposes the network identifiers needed by other modules and by verification steps.
# These outputs let later modules consume the VPC and subnet IDs cleanly.

# -----------------------------------------------------------------------------
# Network outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "selected_azs" {
  description = "Availability Zones selected for the deployment."
  value       = local.selected_azs
}