# =============================================================================
# Observability Module - Variables
# =============================================================================

variable "log_analytics_name" {
  type = string
}

variable "app_insights_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "log_analytics_sku" {
  type    = string
  default = "PerGB2018"
}

variable "retention_in_days" {
  type    = number
  default = 30
}

variable "application_type" {
  type    = string
  default = "web"
}

variable "tags" {
  type    = map(string)
  default = {}
}
