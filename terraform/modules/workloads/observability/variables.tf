variable "name" {
  description = "Base name for observability resources"
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
