# Declares the root input variables for the project.
# These values control naming, AWS access, networking inputs, and database settings.

variable "project_name" {
  description = "Project name used for tagging and naming."
  type        = string
  default     = "wordpress-platform"
}

variable "environment" {
  description = "Environment name used for tagging."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for the deployment."
  type        = string
  default     = "eu-west-3"
}

variable "aws_profile" {
  description = "AWS CLI profile Terraform should use."
  type        = string
}

variable "my_ip_cidr" {
  description = "Public egress IP in CIDR format for restricted SSH access."
  type        = string
}

variable "public_key_path" {
  description = "Path to the local SSH public key for bastion access."
  type        = string
}

variable "db_name" {
  description = "WordPress database name."
  type        = string
  default     = "wordpress"
}

variable "db_user" {
  description = "WordPress database username."
  type        = string
  default     = "wpadmin"
}

variable "db_password" {
  description = "WordPress database password."
  type        = string
  sensitive   = true
}