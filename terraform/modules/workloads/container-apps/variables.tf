variable "name" {
  description = "Name of the Container Apps Environment"
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID (required)"
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "Subnet ID for Container Apps infrastructure (optional)"
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Enable internal load balancer"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the Container Apps Environment"
  type        = map(string)
  default     = {}
}
