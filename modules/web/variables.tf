# Declares the input variables for the web module.
# These values define where the web tier runs and how it connects to the database.

# -----------------------------------------------------------------------------
# Naming / tagging context
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
}

# -----------------------------------------------------------------------------
# Network placement
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where the web tier will be deployed."
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets used by the load balancer."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets used by the web instances."
  type        = list(string)
}

# -----------------------------------------------------------------------------
# WordPress database connection
# -----------------------------------------------------------------------------

variable "db_endpoint" {
  description = "Endpoint address of the database instance."
  type        = string
}

variable "db_name" {
  description = "WordPress database name."
  type        = string
}

variable "db_user" {
  description = "WordPress database username."
  type        = string
}

variable "db_password" {
  description = "WordPress database password."
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Web tier sizing / bootstrap inputs
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for the web tier."
  type        = string
  default     = "t2.micro"
}

variable "user_data_template_path" {
  description = "Path to the user-data template used to bootstrap WordPress."
  type        = string
}

# -----------------------------------------------------------------------------
# Administrative access control
# -----------------------------------------------------------------------------

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion host allowed to SSH into the web tier."
  type        = string
}