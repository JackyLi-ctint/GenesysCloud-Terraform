terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

resource "genesyscloud_integration" "cross_org_integration" {
  intended_state   = "ENABLED"
  integration_type = "custom-rest-actions"
  config {
    name       = var.integration_name
    properties = jsonencode({})
    advanced   = jsonencode({})
    notes      = "Placeholder integration for cross-org migration routing logic"
  }
}

resource "genesyscloud_integration_action" "route_decision" {
  name           = var.integration_action_name
  category       = var.integration_name
  integration_id = genesyscloud_integration.cross_org_integration.id
  secure         = false

  contract_input = jsonencode({
    type     = "object"
    required = ["ConversationAttributes", "Payload"]
    properties = {
      ConversationAttributes = { type = "string" }
      Payload                = { type = "string" }
    }
  })

  contract_output = jsonencode({
    type     = "object"
    required = ["TargetQueue"]
    properties = {
      TargetQueue = { type = "string" }
    }
  })

  config_request {
    request_url_template = var.integration_endpoint_url
    request_type         = "POST"
    request_template     = "$${input.rawRequest}"
    headers = {
      Authorization = var.integration_auth_value
    }
  }

  config_response {
    translation_map          = {}
    translation_map_defaults = {}
    success_template         = "$${rawResult}"
  }
}

output "integration_action_id" {
  description = "ID of the route decision integration action."
  value       = genesyscloud_integration_action.route_decision.id
}
