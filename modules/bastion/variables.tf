# Declares the input variables for the bastion module.
# These values define where the bastion runs and how SSH access is restricted.

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the bastion will be deployed."
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet used for the bastion host."
  type        = string
}

variable "my_ip_cidr" {
  description = "Public egress IP in CIDR format allowed to SSH into the bastion."
  type        = string
}

variable "public_key_path" {
  description = "Path to the local SSH public key file."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the bastion host."
  type        = string
  default     = "t2.micro"
}