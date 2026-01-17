# =============================================================================
# Resource Group Module - Variables
# =============================================================================

variable "name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
