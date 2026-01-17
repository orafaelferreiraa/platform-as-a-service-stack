variable "environment_name" {
  description = "Name of the Container Apps Environment"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for observability"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Use internal load balancer (no public IP)"
  type        = bool
  default     = false
}

variable "managed_identity_id" {
  description = "User assigned managed identity resource ID"
  type        = string
  default     = null
}

variable "container_apps" {
  description = "Map of container apps to create"
  type = map(object({
    revision_mode = optional(string, "Single")
    containers = list(object({
      name   = string
      image  = string
      cpu    = number
      memory = string
      env = optional(map(object({
        value       = optional(string)
        secret_name = optional(string)
      })))
    }))
    min_replicas = optional(number, 0)
    max_replicas = optional(number, 10)
    http_scale_rule = optional(object({
      name                = string
      concurrent_requests = number
    }))
    ingress = optional(object({
      external_enabled = bool
      target_port      = number
      transport        = optional(string, "auto")
    }))
    secrets = optional(map(string))
    registry = optional(object({
      server               = string
      username             = optional(string)
      password_secret_name = optional(string)
      identity             = optional(string)
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
