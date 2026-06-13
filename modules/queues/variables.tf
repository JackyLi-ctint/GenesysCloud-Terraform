variable "queue_names" {
  type        = list(string)
  description = "Queue names expected by migration flows."
}

variable "queue_members" {
  type        = list(string)
  description = "User IDs assigned to each queue."
  default     = []
}

variable "acw_timeout_ms" {
  type        = number
  description = "After-call-work timeout in milliseconds."
  default     = 300000
}
