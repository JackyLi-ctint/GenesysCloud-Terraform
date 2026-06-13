variable "integration_endpoint_url" {
  type        = string
  description = "Integration endpoint URL."
}

variable "integration_auth_value" {
  type        = string
  description = "Integration auth/secret value."
  sensitive   = true
}

variable "integration_name" {
  type        = string
  description = "Name for custom REST integration."
  default     = "CrossOrgIntegration"
}

variable "integration_action_name" {
  type        = string
  description = "Name for integration action."
  default     = "RouteDecisionAction"
}
