variable "name" {
  description = "Name of the Event Grid domain"
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
  description = "ID of the managed identity for authentication"
  type        = string
}

variable "service_bus_topic_id" {
  description = "ID of the Service Bus topic for event subscriptions (optional)"
  type        = string
  default     = null
}

variable "enable_service_bus_integration" {
  description = "Enable Event Grid subscription to Service Bus topic"
  type        = bool
  default     = false
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
