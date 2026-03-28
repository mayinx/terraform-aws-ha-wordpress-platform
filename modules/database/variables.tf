# Declares the input variables for the database module.
# These values define where the database is deployed and how it is configured.

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
  description = "ID of the VPC where the database will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets used for the DB subnet group."
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Database connection settings
# -----------------------------------------------------------------------------

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "db_user" {
  description = "Master username for the database."
  type        = string
}

variable "db_password" {
  description = "Master password for the database."
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Database sizing / storage
# -----------------------------------------------------------------------------

variable "db_instance_class" {
  description = "Instance class for the database."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB."
  type        = number
  default     = 20
}