# Exposes the web tier identifiers needed by later modules and verification steps.
# These outputs surface the ALB DNS name, ASG name, and web security group ID.

# -----------------------------------------------------------------------------
# Web outputs
# -----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = aws_lb.this.dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.this.name
}

output "web_security_group_id" {
  description = "Security group ID attached to the web instances."
  value       = aws_security_group.web.id
}