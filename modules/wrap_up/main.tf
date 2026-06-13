terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

resource "genesyscloud_routing_wrapupcode" "wrap_up_codes" {
  for_each = var.create_wrap_up_codes ? { for c in var.wrap_up_codes : c.name => c } : {}

  name        = each.value.name
  description = each.value.description
}

output "wrap_up_ids" {
  description = "Map of wrap-up code names to IDs when created."
  value       = { for name, code in genesyscloud_routing_wrapupcode.wrap_up_codes : name => code.id }
}
