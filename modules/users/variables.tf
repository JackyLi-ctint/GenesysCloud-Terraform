variable "create_user" {
  type        = bool
  description = "Create demo/service user resource."
  default     = false
}

variable "user_name" {
  type        = string
  description = "Display name for demo/service user."
}

variable "user_email" {
  type        = string
  description = "Email for demo/service user."
}

variable "user_password" {
  type        = string
  description = "Password for demo/service user."
  sensitive   = true
}

variable "user_department" {
  type        = string
  description = "Department for demo/service user."
}

variable "user_title" {
  type        = string
  description = "Title for demo/service user."
}

variable "user_phone_number" {
  type        = string
  description = "Phone number for demo/service user profile."
}

variable "user_employee_id" {
  type        = string
  description = "Employee ID for demo/service user profile."
}

variable "user_employee_type" {
  type        = string
  description = "Employee type for demo/service user profile."
}

variable "user_hire_date" {
  type        = string
  description = "Hire date in YYYY-MM-DD format."
}

variable "user_acd_auto_answer" {
  type        = bool
  description = "Whether demo/service user auto-answers ACD interactions."
}

variable "assign_default_userrole" {
  type        = bool
  description = "Assign baseline employee and user roles to the created user."
  default     = false
}
