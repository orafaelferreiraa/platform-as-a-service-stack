variable "name" {
  description = "Name of the Redis Cache"
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

variable "capacity" {
  description = "Redis Cache capacity (size)"
  type        = number
  default     = 1
}

variable "family" {
  description = "Redis Cache family (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "C"

  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "Family must be 'C' (Basic/Standard) or 'P' (Premium)."
  }
}

variable "sku_name" {
  description = "Redis Cache SKU name"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "SKU must be 'Basic', 'Standard', or 'Premium'."
  }
}

variable "redis_family" {
  description = "Redis Cache family (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "C"

  validation {
    condition     = contains(["C", "P"], var.redis_family)
    error_message = "Family must be 'C' (Basic/Standard) or 'P' (Premium)."
  }
}

variable "maxmemory_policy" {
  description = "Max memory eviction policy"
  type        = string
  default     = "volatile-lru"
}

variable "maxmemory_reserved" {
  description = "Memory reserved for non-cache operations (MB)"
  type        = number
  default     = null
}

variable "maxmemory_delta" {
  description = "Memory delta reserved during scaling (MB)"
  type        = number
  default     = null
}

variable "notify_keyspace_events" {
  description = "Keyspace notifications setting"
  type        = string
  default     = ""
}

variable "aof_backup_enabled" {
  description = "Enable AOF backup (Premium only)"
  type        = bool
  default     = false
}

variable "aof_storage_connection_string" {
  description = "Storage connection string for AOF backup"
  type        = string
  default     = null
  sensitive   = true
}

variable "replicas_per_master" {
  description = "Number of replicas per master (Premium only)"
  type        = number
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration (Premium only)"
  type        = string
  default     = null
}

variable "managed_identity_id" {
  description = "User assigned managed identity resource ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
