variable "name" {
  description = "Name identifier for the platform (team or product name)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.name))
    error_message = "Name must be lowercase alphanumeric only."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
