# Defines the top-level project composition.
# The root module wires together the infrastructure modules and passes shared inputs into them.

module "network" {
  source = "./modules/network"

  project_name = var.project_name
  environment  = var.environment
}

module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
}