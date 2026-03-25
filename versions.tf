# Defines the Terraform CLI version and required provider versions for this project.
# This keeps provider selection explicit and makes the configuration easier to reproduce.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}