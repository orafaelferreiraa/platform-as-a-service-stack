variable "name" {
  description = "Name of the storage account (lowercase, no hyphens, max 24 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
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

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Invalid replication type."
  }
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key authentication"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Days to retain soft deleted blobs (0 to disable)"
  type        = number
  default     = 7
}

variable "container_soft_delete_retention_days" {
  description = "Days to retain soft deleted containers (0 to disable)"
  type        = number
  default     = 7
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

variable "network_rules" {
  description = "Network rules configuration"
  type = object({
    default_action             = string
    bypass                     = list(string)
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
