variable "name" {
  description = "Name of the virtual network"
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

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Subnet CIDR configurations"
  type = object({
    default           = string
    private_endpoints = string
    container_apps    = optional(string)
    sql               = optional(string)
    redis             = optional(string)
  })
  default = {
    default           = "10.0.0.0/24"
    private_endpoints = "10.0.1.0/24"
    container_apps    = "10.0.2.0/23"
    sql               = "10.0.4.0/24"
    redis             = "10.0.5.0/24"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
