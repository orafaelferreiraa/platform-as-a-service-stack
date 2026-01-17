# =============================================================================
# Platform Variables
# NO environment variable - platform is identified by name + location only
# =============================================================================

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "name" {
  description = "Platform name (team or product name - lowercase alphanumeric only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.name))
    error_message = "Name must be lowercase alphanumeric only (no hyphens or special characters)."
  }
}

# Region is hardcoded to eastus2 - NOT configurable via pipeline
variable "location" {
  description = "Azure region (hardcoded default - do not override)"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Feature Flags - Enable/disable platform components
# =============================================================================

variable "enable_vnet" {
  description = "Enable VNet Spoke"
  type        = bool
  default     = false
}

variable "enable_observability" {
  description = "Enable Observability (Log Analytics + App Insights)"
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
  default     = false
}

variable "enable_service_bus" {
  description = "Enable Service Bus"
  type        = bool
  default     = false
}

variable "enable_event_grid" {
  description = "Enable Event Grid"
  type        = bool
  default     = false
}

variable "enable_sql" {
  description = "Enable SQL Server & Database"
  type        = bool
  default     = false
}

variable "enable_redis" {
  description = "Enable Redis Cache"
  type        = bool
  default     = false
}

variable "enable_container_apps" {
  description = "Enable Container Apps"
  type        = bool
  default     = false
}

# =============================================================================
# VNet Configuration
# =============================================================================

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "vnet_subnets" {
  description = "Subnet CIDR configurations"
  type = object({
    default           = string
    private_endpoints = string
    container_apps    = optional(string)
    sql               = optional(string)
    redis             = optional(string)
  })
  default = {
    default           = "10.0.0.0/24"
    private_endpoints = "10.0.1.0/24"
    container_apps    = "10.0.2.0/23"
    sql               = "10.0.4.0/24"
    redis             = "10.0.5.0/24"
  }
}

# =============================================================================
# Service Bus Configuration
# =============================================================================

variable "service_bus_sku" {
  description = "Service Bus SKU"
  type        = string
  default     = "Standard"
}

variable "service_bus_queues" {
  description = "Service Bus queues to create"
  type = map(object({
    max_delivery_count                   = optional(number, 10)
    lock_duration                        = optional(string, "PT1M")
    max_size_in_megabytes                = optional(number, 1024)
    dead_lettering_on_message_expiration = optional(bool, true)
    requires_duplicate_detection         = optional(bool, false)
    requires_session                     = optional(bool, false)
    default_message_ttl                  = optional(string)
  }))
  default = {}
}

variable "service_bus_topics" {
  description = "Service Bus topics to create"
  type = map(object({
    max_size_in_megabytes            = optional(number, 1024)
    requires_duplicate_detection     = optional(bool, false)
    support_ordering                 = optional(bool, false)
    default_message_ttl              = optional(string)
    auto_delete_on_idle              = optional(string)
    duplicate_detection_history_time = optional(string)
  }))
  default = {}
}

# =============================================================================
# SQL Configuration
# =============================================================================

variable "sql_sku" {
  description = "SQL Database SKU"
  type        = string
  default     = "S0"
}

variable "sql_max_size_gb" {
  description = "SQL Database max size in GB"
  type        = number
  default     = 32
}

# =============================================================================
# Redis Configuration
# =============================================================================

variable "redis_sku" {
  description = "Redis Cache SKU"
  type        = string
  default     = "Standard"
}

variable "redis_capacity" {
  description = "Redis Cache capacity"
  type        = number
  default     = 1
}

variable "redis_family" {
  description = "Redis Cache family (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "C"
}

# =============================================================================
# Container Apps Configuration
# =============================================================================

variable "container_apps" {
  description = "Container Apps to create"
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
