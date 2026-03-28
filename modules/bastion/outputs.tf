# Exposes the bastion identifiers needed for verification and for downstream access rules.

# -----------------------------------------------------------------------------
# Bastion outputs
# -----------------------------------------------------------------------------

output "bastion_public_ip" {
  description = "Public IP address of the bastion host."
  value       = aws_instance.this.public_ip
}

output "bastion_security_group_id" {
  description = "Security group ID attached to the bastion host."
  value       = aws_security_group.bastion.id
}