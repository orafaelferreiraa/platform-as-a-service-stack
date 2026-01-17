# =============================================================================
# Managed Identity Module - Variables
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

variable "tags" {
  type    = map(string)
  default = {}
}
