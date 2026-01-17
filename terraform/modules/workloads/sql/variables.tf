# =============================================================================
# SQL Module - Variables
# =============================================================================

variable "server_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "sql_version" {
  type    = string
  default = "12.0"
}

variable "administrator_login" {
  type    = string
  default = "sql_admin"
}

variable "minimum_tls_version" {
  type    = string
  default = "1.2"
}

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "azuread_administrator" {
  type = object({
    login_username              = string
    object_id                   = string
    tenant_id                   = optional(string)
    azuread_authentication_only = optional(bool, false)
  })
  default = null
}

variable "collation" {
  type    = string
  default = "SQL_Latin1_General_CP1_CI_AS"
}

variable "max_size_gb" {
  type    = number
  default = 2
}

variable "sku_name" {
  type    = string
  default = "S0"
}

variable "zone_redundant" {
  type    = bool
  default = false
}

variable "auto_pause_delay_in_minutes" {
  type    = number
  default = 60
}

variable "min_capacity" {
  type    = number
  default = 0.5
}

variable "read_replica_count" {
  type    = number
  default = 0
}

variable "read_scale" {
  type    = bool
  default = false
}

variable "short_term_retention_days" {
  type    = number
  default = 7
}

variable "long_term_retention" {
  type = object({
    weekly_retention  = optional(string)
    monthly_retention = optional(string)
    yearly_retention  = optional(string)
    week_of_year      = optional(number)
  })
  default = null
}

variable "allow_azure_services" {
  type    = bool
  default = true
}

variable "firewall_rules" {
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

variable "vnet_rules" {
  type = list(object({
    name      = string
    subnet_id = string
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
