variable "name" {
  description = "Name of the Service Bus namespace"
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

variable "managed_identity_id" {
  description = "Principal ID of the managed identity for RBAC"
  type        = string
  default     = null
}

variable "enable_managed_identity_rbac" {
  description = "Whether to create RBAC role assignments for managed identity"
  type        = bool
  default     = false
}

variable "sku" {
  description = "SKU of the Service Bus namespace"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags to apply to resources"
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
