output "user_ids" {
  description = "User IDs created by this module; empty when create_user=false."
  value       = [for u in genesyscloud_user.service_user : u.id]
}
