# =============================================================================
# Service Bus Module - Variables
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

variable "sku" {
  type    = string
  default = "Standard"
}

variable "capacity" {
  type    = number
  default = 0
}

variable "premium_messaging_partitions" {
  type    = number
  default = 0
}

variable "local_auth_enabled" {
  type    = bool
  default = false
}

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "minimum_tls_version" {
  type    = string
  default = "1.2"
}

variable "queues" {
  type = list(object({
    name                                    = string
    max_size_in_megabytes                   = optional(number, 1024)
    default_message_ttl                     = optional(string)
    lock_duration                           = optional(string, "PT1M")
    max_delivery_count                      = optional(number, 10)
    dead_lettering_on_message_expiration    = optional(bool, true)
    enable_partitioning                     = optional(bool, false)
    requires_duplicate_detection            = optional(bool, false)
    duplicate_detection_history_time_window = optional(string)
    requires_session                        = optional(bool, false)
  }))
  default = []
}

variable "topics" {
  type = list(object({
    name                                    = string
    max_size_in_megabytes                   = optional(number, 1024)
    default_message_ttl                     = optional(string)
    enable_partitioning                     = optional(bool, false)
    requires_duplicate_detection            = optional(bool, false)
    duplicate_detection_history_time_window = optional(string)
    support_ordering                        = optional(bool, false)
  }))
  default = []
}

variable "subscriptions" {
  type = list(object({
    name                                 = string
    topic_name                           = string
    max_delivery_count                   = optional(number, 10)
    default_message_ttl                  = optional(string)
    lock_duration                        = optional(string, "PT1M")
    dead_lettering_on_message_expiration = optional(bool, true)
    requires_session                     = optional(bool, false)
  }))
  default = []
}

variable "identity_principal_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
