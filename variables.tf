variable "genesyscloud_oauthclient_id" {
  type        = string
  description = "OAuth client ID for the target Genesys Cloud org."
}

variable "genesyscloud_oauthclient_secret" {
  type        = string
  description = "OAuth client secret for the target Genesys Cloud org."
  sensitive   = true
}

variable "genesyscloud_region" {
  type        = string
  description = "Genesys Cloud region for the target org (for example: us-east-1)."
}

variable "integration_endpoint_url" {
  type        = string
  description = "Integration endpoint URL used by the integration action."
}

variable "integration_auth_value" {
  type        = string
  description = "Integration auth/secret value for endpoint calls."
  sensitive   = true
}

variable "integration_name" {
  type        = string
  description = "Name of the custom REST integration."
  default     = "CrossOrgIntegration"
}

variable "integration_action_name" {
  type        = string
  description = "Name of the integration action called by the flow."
  default     = "RouteDecisionAction"
}

variable "flow_name" {
  type        = string
  description = "Name of the Architect flow to deploy."
  default     = "CrossOrgMainFlow"
}

variable "flow_filepath" {
  type        = string
  description = "Path to the flow YAML file."
  default     = "./modules/deploy_flows/CrossOrgMainFlow.yaml"
}

variable "queue_names" {
  type        = list(string)
  description = "List of queue names used by migration flows."
  default     = ["Support", "Sales", "Billing", "General"]
}

variable "acw_timeout_ms" {
  type        = number
  description = "Queue after-call-work timeout in milliseconds."
  default     = 300000
}

variable "create_user" {
  type        = bool
  description = "Create a demo/service user. Keep false by default for safer migrations."
  default     = false
}

variable "user_name" {
  type        = string
  description = "Display name for optional demo/service user."
  default     = "Placeholder User"
}

variable "user_email" {
  type        = string
  description = "Email for optional demo/service user."
  default     = "placeholder.user@example.com"
}

variable "user_password" {
  type        = string
  description = "Password for optional demo/service user. Supply securely when create_user=true."
  sensitive   = true
  default     = ""
}

variable "user_department" {
  type        = string
  description = "Department for optional demo/service user."
  default     = "Development"
}

variable "user_title" {
  type        = string
  description = "Title for optional demo/service user."
  default     = "Agent"
}

variable "user_phone_number" {
  type        = string
  description = "Phone number for optional demo/service user profile."
  default     = "+10000000000"
}

variable "user_employee_id" {
  type        = string
  description = "Employee ID for optional demo/service user profile."
  default     = "EMP-PLACEHOLDER"
}

variable "user_employee_type" {
  type        = string
  description = "Employee type for optional demo/service user profile."
  default     = "Full-time"
}

variable "user_hire_date" {
  type        = string
  description = "Hire date for optional demo/service user in YYYY-MM-DD format."
  default     = "2021-01-01"
}

variable "user_acd_auto_answer" {
  type        = bool
  description = "Whether optional demo/service user auto-answers ACD interactions."
  default     = true
}

variable "assign_default_userrole" {
  type        = bool
  description = "Assign baseline employee and user roles to optional demo/service user."
  default     = false
}

variable "create_wrap_up_codes" {
  type        = bool
  description = "Create custom wrap-up codes used by migration flows."
  default     = false
}

variable "skill_names" {
  type        = list(string)
  description = "Optional routing skills to ensure exist in target org."
  default     = []
}

variable "language_names" {
  type        = list(string)
  description = "Optional routing languages to ensure exist in target org."
  default     = []
}

variable "wrap_up_codes" {
  type = list(object({
    name        = string
    description = string
  }))
  description = "Wrap-up code definitions for optional creation."
  default = [
    {
      name        = "Sales"
      description = "Placeholder wrap-up code for sales outcomes"
    },
    {
      name        = "Support"
      description = "Placeholder wrap-up code for support outcomes"
    },
    {
      name        = "Escalation"
      description = "Placeholder wrap-up code for escalated outcomes"
    }
  ]
}

check "integration_endpoint_placeholder" {
  assert {
    condition     = var.integration_endpoint_url != "REPLACE_WITH_INTEGRATION_ENDPOINT_URL"
    error_message = "Set a real integration_endpoint_url before real deployment/validation."
  }
}
