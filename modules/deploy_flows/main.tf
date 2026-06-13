terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

resource "genesyscloud_flow" "main_flow" {
  name     = var.flow_name
  filepath = var.flow_filepath
}

output "flow_id" {
  description = "ID of the deployed flow."
  value       = genesyscloud_flow.main_flow.id
}

output "flow_name" {
  description = "Name of the deployed flow."
  value       = genesyscloud_flow.main_flow.name
}
