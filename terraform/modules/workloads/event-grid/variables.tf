variable "name" {
  description = "Name of the Event Grid topic"
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

variable "input_schema" {
  description = "Input schema for events"
  type        = string
  default     = "EventGridSchema"

  validation {
    condition     = contains(["EventGridSchema", "CustomEventSchema", "CloudEventSchemaV1_0"], var.input_schema)
    error_message = "Input schema must be 'EventGridSchema', 'CustomEventSchema', or 'CloudEventSchemaV1_0'."
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

variable "subscriptions" {
  description = "Map of event subscriptions to create"
  type = map(object({
    endpoint_type         = string # webhook, service_bus_queue, service_bus_topic, storage_queue
    endpoint_url          = optional(string)
    service_bus_queue_id  = optional(string)
    service_bus_topic_id  = optional(string)
    storage_account_id    = optional(string)
    storage_queue_name    = optional(string)
    event_types           = optional(list(string))
    event_delivery_schema = optional(string, "EventGridSchema")
    retry_policy = optional(object({
      max_delivery_attempts = number
      event_time_to_live    = number
    }))
    subject_filter = optional(object({
      subject_begins_with = optional(string)
      subject_ends_with   = optional(string)
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
