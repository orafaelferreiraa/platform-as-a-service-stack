variable "name" {
  description = "Name of the Redis cache"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Premium SKU Redis (optional)"
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU name for Redis cache"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "family" {
  description = "SKU family for Redis cache"
  type        = string
  default     = "C"
  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "Family must be C (Basic/Standard) or P (Premium)."
  }
}

variable "capacity" {
  description = "Capacity for Redis cache"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags to apply to the Redis cache"
  type        = map(string)
  default     = {}
}

variable "enable_observability" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics"
  type        = string
  default     = null
}
