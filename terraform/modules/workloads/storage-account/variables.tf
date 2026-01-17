# =============================================================================
# Storage Account Module - Variables
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

variable "account_tier" {
  type    = string
  default = "Standard"
}

variable "account_replication_type" {
  type    = string
  default = "LRS"
}

variable "account_kind" {
  type    = string
  default = "StorageV2"
}

variable "https_traffic_only_enabled" {
  type    = bool
  default = true
}

variable "min_tls_version" {
  type    = string
  default = "TLS1_2"
}

variable "allow_public_access" {
  type    = bool
  default = false
}

variable "enable_blob_properties" {
  type    = bool
  default = true
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "container_delete_retention_days" {
  type    = number
  default = 7
}

variable "blob_delete_retention_days" {
  type    = number
  default = 7
}

variable "enable_network_rules" {
  type    = bool
  default = false
}

variable "network_rules_default_action" {
  type    = string
  default = "Deny"
}

variable "network_rules_ip_rules" {
  type    = list(string)
  default = []
}

variable "network_rules_subnet_ids" {
  type    = list(string)
  default = []
}

variable "network_rules_bypass" {
  type    = list(string)
  default = ["AzureServices"]
}

variable "containers" {
  type    = list(string)
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
