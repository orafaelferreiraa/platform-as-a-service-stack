# =============================================================================
# Naming Module - Variables
# =============================================================================

variable "name" {
  description = "Nome base para os recursos (time ou produto)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,20}$", var.name))
    error_message = "O nome deve começar com letra, conter apenas letras, números e hífens, com 2-21 caracteres."
  }
}

variable "location" {
  description = "Região Azure para os recursos"
  type        = string
  default     = "eastus2"
}
