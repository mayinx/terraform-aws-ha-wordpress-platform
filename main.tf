# Defines the top-level project composition.
# The root module wires together the infrastructure modules and passes shared inputs into them.

module "network" {
  source = "./modules/network"

  project_name = var.project_name
  environment  = var.environment
}