output "flow_id" {
  description = "ID of the deployed Architect flow."
  value       = module.deploy_flows.flow_id
}

output "flow_name" {
  description = "Name of the deployed Architect flow."
  value       = module.deploy_flows.flow_name
}

output "queue_ids" {
  description = "Map of queue names to IDs."
  value       = module.queues.queue_ids
}

output "integration_action_id" {
  description = "Integration action ID used by the flow."
  value       = module.data_actions.integration_action_id
}

output "routing_skill_ids" {
  description = "Skill IDs created or resolved by routing module."
  value       = module.routing.skill_ids
}

output "routing_language_ids" {
  description = "Language IDs created or resolved by routing module."
  value       = module.routing.language_ids
}

output "user_ids" {
  description = "Optional user IDs created by the users module."
  value       = module.users.user_ids
}

output "wrap_up_ids" {
  description = "Wrap-up code IDs created when enabled."
  value       = module.wrap_up.wrap_up_ids
}
