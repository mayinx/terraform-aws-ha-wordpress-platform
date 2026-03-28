# Exposes the database identifiers needed by later modules and verification steps.
# These outputs make the database endpoint and security group available at the root level.

# -----------------------------------------------------------------------------
# Database outputs
# -----------------------------------------------------------------------------

output "db_endpoint" {
  description = "Endpoint address of the database instance."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}

output "db_security_group_id" {
  description = "Security group ID attached to the database instance."
  value       = aws_security_group.db.id
}