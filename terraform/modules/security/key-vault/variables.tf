variable "name" {
  description = "Name of the Key Vault"
  type        = string

  validation {
    condition     = length(var.name) <= 24
    error_message = "Key Vault name must be 24 characters or less."
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

variable "sku_name" {
  description = "SKU name for Key Vault (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  description = "Days to retain deleted vaults (7-90)"
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention must be between 7 and 90 days."
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network ACLs configuration"
  type = object({
    default_action             = string
    bypass                     = string
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

variable "enable_managed_identity_access" {
  description = "Enable RBAC assignment for managed identity"
  type        = bool
  default     = false
}

variable "managed_identity_principal_id" {
  description = "Principal ID of managed identity to grant secrets access"
  type        = string
  default     = null
}

variable "secrets" {
  description = "Map of secrets to create in Key Vault (key = secret name, value = secret value)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to the Key Vault"
  type        = map(string)
  default     = {}
}
