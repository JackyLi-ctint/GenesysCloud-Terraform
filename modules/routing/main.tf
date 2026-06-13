terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

resource "genesyscloud_routing_skill" "skills" {
  for_each = toset(var.skill_names)

  name = each.value
}

resource "genesyscloud_routing_language" "languages" {
  for_each = toset(var.language_names)

  name = each.value
}

output "skill_ids" {
  description = "Map of skill names to IDs."
  value       = { for k, v in genesyscloud_routing_skill.skills : k => v.id }
}

output "language_ids" {
  description = "Map of language names to IDs."
  value       = { for k, v in genesyscloud_routing_language.languages : k => v.id }
}
