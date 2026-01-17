variable "server_name" {
  description = "Name of the SQL Server"
  type        = string
}

variable "database_name" {
  description = "Name of the SQL Database"
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

variable "sql_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
}

variable "administrator_login" {
  description = "Administrator login (defaults to sql_admin if not set)"
  type        = string
  default     = null
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

variable "azuread_admin_login" {
  description = "Azure AD admin login username"
  type        = string
  default     = null
}

variable "azuread_admin_object_id" {
  description = "Azure AD admin object ID"
  type        = string
  default     = null
}

variable "azuread_authentication_only" {
  description = "Use Azure AD authentication only"
  type        = bool
  default     = false
}

variable "collation" {
  description = "Database collation"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "max_size_gb" {
  description = "Maximum database size in GB"
  type        = number
  default     = 32
}

variable "sku_name" {
  description = "SKU name for the database"
  type        = string
  default     = "S0"
}

variable "zone_redundant" {
  description = "Enable zone redundancy"
  type        = bool
  default     = false
}

variable "geo_backup_enabled" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = true
}

variable "short_term_retention_days" {
  description = "Short-term backup retention in days (1-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.short_term_retention_days == null || (var.short_term_retention_days >= 1 && var.short_term_retention_days <= 35)
    error_message = "Short-term retention must be between 1 and 35 days."
  }
}

variable "long_term_retention" {
  description = "Long-term retention policy"
  type = object({
    weekly_retention  = optional(string)
    monthly_retention = optional(string)
    yearly_retention  = optional(string)
    week_of_year      = optional(number)
  })
  default = null
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the server"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet ID for VNet service endpoint"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
