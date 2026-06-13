variable "skill_names" {
  type        = list(string)
  description = "Optional routing skills to create."
  default     = []
}

variable "language_names" {
  type        = list(string)
  description = "Optional routing languages to create."
  default     = []
}
