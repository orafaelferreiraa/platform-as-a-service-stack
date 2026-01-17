# =============================================================================
# Redis Cache Module - Variables
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

variable "capacity" {
  type    = number
  default = 0
}

variable "family" {
  type    = string
  default = "C"
}

variable "sku_name" {
  type    = string
  default = "Basic"
}

variable "non_ssl_port_enabled" {
  type    = bool
  default = false
}

variable "minimum_tls_version" {
  type    = string
  default = "1.2"
}

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "redis_version" {
  type    = string
  default = "6"
}

variable "aof_backup_enabled" {
  type    = bool
  default = false
}

variable "aof_storage_connection_string_0" {
  type    = string
  default = null
}

variable "aof_storage_connection_string_1" {
  type    = string
  default = null
}

variable "maxmemory_reserved" {
  type    = number
  default = null
}

variable "maxmemory_delta" {
  type    = number
  default = null
}

variable "maxmemory_policy" {
  type    = string
  default = "volatile-lru"
}

variable "notify_keyspace_events" {
  type    = string
  default = ""
}

variable "rdb_backup_enabled" {
  type    = bool
  default = false
}

variable "rdb_backup_frequency" {
  type    = number
  default = null
}

variable "rdb_backup_max_snapshot_count" {
  type    = number
  default = null
}

variable "rdb_storage_connection_string" {
  type    = string
  default = null
}

variable "identity_principal_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
