variable "name" {
  description = "Name of the virtual network"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "default_subnet_prefix" {
  description = "Address prefix for default subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "container_apps_subnet_prefix" {
  description = "Address prefix for Container Apps subnet"
  type        = string
  default     = "10.0.2.0/23"
}

variable "container_apps_subnet_name" {
  description = "Name for the Container Apps subnet (should include unique suffix)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
