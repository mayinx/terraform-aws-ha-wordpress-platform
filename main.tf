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

module "bastion" {
  source = "./modules/bastion"

  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_ids[0]
  my_ip_cidr       = var.my_ip_cidr
  public_key_path  = var.public_key_path
  instance_type    = var.bastion_instance_type
}

module "web" {
  source = "./modules/web"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.network.vpc_id
  public_subnet_ids         = module.network.public_subnet_ids
  private_subnet_ids        = module.network.private_subnet_ids
  db_endpoint               = module.database.db_endpoint
  db_name                   = var.db_name
  db_user                   = var.db_user
  db_password               = var.db_password
  instance_type             = var.web_instance_type
  user_data_template_path   = "${path.module}/user_data/wordpress.sh.tftpl"
  bastion_security_group_id = module.bastion.bastion_security_group_id
}