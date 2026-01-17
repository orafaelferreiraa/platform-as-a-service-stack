# =============================================================================
# VNet Spoke Module - Variables
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

variable "address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

variable "subnet_prefix" {
  type    = string
  default = "snet"
}

variable "subnets" {
  type = object({
    default           = string
    container_apps    = optional(string, "10.0.16.0/21")
    private_endpoints = optional(string, "10.0.24.0/24")
  })
  default = {
    default           = "10.0.0.0/24"
    container_apps    = "10.0.16.0/21"
    private_endpoints = "10.0.24.0/24"
  }
}

variable "enable_service_endpoints" {
  type    = bool
  default = true
}

variable "enable_container_apps_subnet" {
  type    = bool
  default = false
}

variable "enable_private_endpoints_subnet" {
  type    = bool
  default = false
}

variable "enable_nsg" {
  type    = bool
  default = true
}

variable "nsg_name" {
  type    = string
  default = "nsg-default"
}

variable "tags" {
  type    = map(string)
  default = {}
}
