variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "name" {
  description = "Name for the platform (team or product - lowercase alphanumeric)"
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

# Feature flags - all enabled by default
variable "enable_managed_identity" {
  description = "Enable Managed Identity (required by: Storage, Service Bus, Event Grid, SQL, Key Vault for RBAC)"
  type        = bool
  default     = true
}

variable "enable_vnet" {
  description = "Enable Virtual Network Spoke"
  type        = bool
  default     = true
}

variable "enable_observability" {
  description = "Enable Observability (Log Analytics, Application Insights)"
  type        = bool
  default     = true
}

variable "enable_key_vault" {
  description = "Enable Key Vault"
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Enable Storage Account"
  type        = bool
  default     = true
}

variable "enable_service_bus" {
  description = "Enable Service Bus"
  type        = bool
  default     = true
}

variable "enable_event_grid" {
  description = "Enable Event Grid"
  type        = bool
  default     = true
}

variable "enable_sql" {
  description = "Enable SQL Server and Database"
  type        = bool
  default     = true
}

variable "enable_container_apps" {
  description = "Enable Container Apps Environment"
  type        = bool
  default     = true
}

# Common tags
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
