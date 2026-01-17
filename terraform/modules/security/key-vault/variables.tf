# =============================================================================
# Key Vault Module - Variables
# =============================================================================

variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{2,23}$", var.name))
    error_message = "Nome do Key Vault deve ter 3-24 caracteres, começar com letra."
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "sku_name" {
  type    = string
  default = "standard"
}

variable "soft_delete_retention_days" {
  type    = number
  default = 7
}

variable "purge_protection_enabled" {
  type    = bool
  default = false
}

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "enable_network_acls" {
  type    = bool
  default = false
}

variable "network_default_action" {
  type    = string
  default = "Deny"
}

variable "allowed_ip_ranges" {
  type    = list(string)
  default = []
}

variable "allowed_subnet_ids" {
  type    = list(string)
  default = []
}

variable "secrets_user_principal_ids" {
  type    = map(string)
  default = {}
}

variable "secrets_officer_principal_ids" {
  type    = map(string)
  default = {}
}

variable "secrets" {
  description = "Map de secrets a serem criados (nome => valor)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
