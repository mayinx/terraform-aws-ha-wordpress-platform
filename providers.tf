# Configures the AWS provider and shared default tags for all managed resources.
# The profile is kept configurable so local development can use a dedicated AWS CLI profile.

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}