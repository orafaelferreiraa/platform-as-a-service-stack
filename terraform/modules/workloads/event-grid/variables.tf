# =============================================================================
# Event Grid Module - Variables
# =============================================================================

variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "source_arm_resource_id" {
  type        = string
  description = "The ARM resource ID of the source (e.g., Storage Account, Resource Group)"
}

variable "topic_type" {
  type        = string
  description = "The type of source (e.g., Microsoft.Storage.StorageAccounts, Microsoft.Resources.ResourceGroups)"
  default     = "Microsoft.Storage.StorageAccounts"
}

variable "subscriptions" {
  type = list(object({
    name                 = string
    endpoint_type        = string # "service_bus_queue", "service_bus_topic", "storage_queue", "webhook"
    endpoint_id          = optional(string)
    storage_account_id   = optional(string)
    queue_name           = optional(string)
    webhook_url          = optional(string)
    included_event_types = list(string)
    subject_filter = optional(object({
      subject_begins_with = optional(string)
      subject_ends_with   = optional(string)
      case_sensitive      = optional(bool, false)
    }))
    advanced_filters = optional(list(object({
      type   = string # "string_contains", "string_begins_with", "string_ends_with"
      key    = string
      values = list(string)
    })))
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
