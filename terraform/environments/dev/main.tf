locals {
  name_prefix = "${var.project}-${var.environment}"
}

module "network" {
  source      = "../../modules/network"
  name_prefix = local.name_prefix
}

module "iam" {
  source                         = "../../modules/iam"
  name_prefix                    = local.name_prefix
  create_roles                   = var.create_iam_roles
  existing_service_role_name     = var.service_role_name
  existing_instance_profile_name = var.instance_profile_name
}

module "rds" {
  source             = "../../modules/rds"
  name_prefix        = local.name_prefix
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  instance_class     = var.db_instance_class
  security_group_ids = [module.network.rds_security_group_id]
}

module "beanstalk" {
  source       = "../../modules/beanstalk"
  name_prefix  = local.name_prefix
  app_name     = "${local.name_prefix}-app"
  env_name     = "${local.name_prefix}-env"
  app_zip_path = "${path.root}/${var.app_zip_path}"

  version_label = var.version_label

  vpc_id                      = module.network.vpc_id
  subnet_ids                  = module.network.subnet_ids
  instance_security_group_ids = [module.network.app_security_group_id]

  service_role_name     = module.iam.service_role_name
  instance_profile_name = module.iam.instance_profile_name

  env_vars = {
    DATABASE_URL = module.rds.database_url
    STATIC_TOKEN = var.static_token
  }

  instance_type = var.instance_type
  min_instances = var.min_instances
  max_instances = var.max_instances

  deployment_policy                = var.deployment_policy
  batch_size_type                  = var.batch_size_type
  batch_size                       = var.batch_size
  traffic_split_percent            = var.traffic_split_percent
  traffic_split_evaluation_minutes = var.traffic_split_evaluation_minutes
}

module "budget" {
  source      = "../../modules/budget"
  count       = var.budget_email == "" ? 0 : 1
  name_prefix = local.name_prefix
  limit_usd   = var.budget_limit_usd
  email       = var.budget_email
}
