variable "name" {
  description = "Name of the Service Bus namespace"
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

variable "sku" {
  description = "SKU for Service Bus namespace"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be 'Basic', 'Standard', or 'Premium'."
  }
}

variable "capacity" {
  description = "Capacity for Premium SKU (1, 2, 4, 8, or 16)"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 4, 8, 16], var.capacity)
    error_message = "Capacity must be 1, 2, 4, 8, or 16."
  }
}

variable "premium_messaging_partitions" {
  description = "Number of messaging partitions for Premium SKU"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 4], var.premium_messaging_partitions)
    error_message = "Premium messaging partitions must be 1, 2, or 4."
  }
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "managed_identity_id" {
  description = "User assigned managed identity resource ID"
  type        = string
  default     = null
}

variable "managed_identity_principal_id" {
  description = "Principal ID of managed identity for RBAC"
  type        = string
  default     = null
}

variable "queues" {
  description = "Map of queues to create"
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

variable "topics" {
  description = "Map of topics to create"
  type = map(object({
    max_size_in_megabytes                   = optional(number, 1024)
    requires_duplicate_detection            = optional(bool, false)
    support_ordering                        = optional(bool, false)
    default_message_ttl                     = optional(string)
    auto_delete_on_idle                     = optional(string)
    duplicate_detection_history_time_window = optional(string)
  }))
  default = {}
}

variable "subscriptions" {
  description = "Map of topic subscriptions to create"
  type = map(object({
    name                                 = string
    topic_name                           = string
    max_delivery_count                   = optional(number, 10)
    lock_duration                        = optional(string, "PT1M")
    dead_lettering_on_message_expiration = optional(bool, true)
    requires_session                     = optional(bool, false)
    default_message_ttl                  = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
