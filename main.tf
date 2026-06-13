terraform {
  required_version = ">= 1.5.0"

  backend "remote" {
    # Bootstrap-required placeholder: replace before terraform init.
    organization = "REPLACE_WITH_TFC_ORGANIZATION"

    workspaces {
      prefix = "genesys_migration_"
    }
  }

  required_providers {
    genesyscloud = {
      source  = "mypurecloud/genesyscloud"
      version = "~> 1.0"
    }
  }
}

provider "genesyscloud" {
  oauthclient_id     = var.genesyscloud_oauthclient_id
  oauthclient_secret = var.genesyscloud_oauthclient_secret
  aws_region         = var.genesyscloud_region
}

module "users" {
  source = "./modules/users"

  create_user             = var.create_user
  user_name               = var.user_name
  user_email              = var.user_email
  user_password           = var.user_password
  user_department         = var.user_department
  user_title              = var.user_title
  user_phone_number       = var.user_phone_number
  user_employee_id        = var.user_employee_id
  user_employee_type      = var.user_employee_type
  user_hire_date          = var.user_hire_date
  user_acd_auto_answer    = var.user_acd_auto_answer
  assign_default_userrole = var.assign_default_userrole
}

module "queues" {
  source = "./modules/queues"

  queue_names    = var.queue_names
  queue_members  = module.users.user_ids
  acw_timeout_ms = var.acw_timeout_ms
}

module "data_actions" {
  source = "./modules/data_actions"

  integration_endpoint_url = var.integration_endpoint_url
  integration_auth_value   = var.integration_auth_value
  integration_name         = var.integration_name
  integration_action_name  = var.integration_action_name
}

module "deploy_flows" {
  source = "./modules/deploy_flows"

  flow_name     = var.flow_name
  flow_filepath = var.flow_filepath
}

module "routing" {
  source = "./modules/routing"

  skill_names    = var.skill_names
  language_names = var.language_names
}

module "wrap_up" {
  source = "./modules/wrap_up"

  create_wrap_up_codes = var.create_wrap_up_codes
  wrap_up_codes        = var.wrap_up_codes
}
