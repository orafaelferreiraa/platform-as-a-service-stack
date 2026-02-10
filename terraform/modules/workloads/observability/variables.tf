variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "naming" {
  description = "Naming module output"
  type = object({
    log_analytics_workspace = string
    application_insights    = string
  })
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "managed_identity_resource_id" {
  description = "Resource ID of the User-Assigned Managed Identity. When provided, attaches the identity to Log Analytics"
  type        = string
  default     = null
}
