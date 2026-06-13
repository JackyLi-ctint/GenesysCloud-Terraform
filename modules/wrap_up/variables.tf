variable "create_wrap_up_codes" {
  type        = bool
  description = "Create wrap-up code resources."
  default     = false
}

variable "wrap_up_codes" {
  type = list(object({
    name        = string
    description = string
  }))
  description = "Wrap-up code definitions."
  default     = []
}
