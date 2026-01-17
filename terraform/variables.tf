# =============================================================================
# Root Variables - Platform as a Service Stack
# =============================================================================

# =============================================================================
# REQUIRED - Inputs obrigatórios
# =============================================================================

variable "name" {
  description = "Nome da plataforma (time ou produto - lowercase alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,14}$", var.name))
    error_message = "O nome deve começar com letra minúscula, conter apenas letras minúsculas e números, com 2-15 caracteres."
  }
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# =============================================================================
# Feature Flags - Habilitar/Desabilitar recursos
# =============================================================================

variable "enable_vnet" {
  description = "Habilitar VNet Spoke"
  type        = bool
  default     = false
}

variable "enable_observability" {
  description = "Habilitar Log Analytics + App Insights"
  type        = bool
  default     = true
}

variable "enable_key_vault" {
  description = "Habilitar Key Vault"
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Habilitar Storage Account"
  type        = bool
  default     = false
}

variable "enable_service_bus" {
  description = "Habilitar Service Bus"
  type        = bool
  default     = false
}

variable "enable_event_grid" {
  description = "Habilitar Event Grid"
  type        = bool
  default     = false
}

variable "enable_sql" {
  description = "Habilitar SQL Server + Database"
  type        = bool
  default     = false
}

variable "enable_redis" {
  description = "Habilitar Redis Cache"
  type        = bool
  default     = false
}

variable "enable_container_apps" {
  description = "Habilitar Container Apps"
  type        = bool
  default     = false
}

# =============================================================================
# VNet Configuration
# =============================================================================

variable "vnet_config" {
  description = "Configuração da VNet Spoke"
  type = object({
    address_space            = optional(list(string), ["10.0.0.0/16"])
    subnets = optional(object({
      default           = optional(string, "10.0.0.0/24")
      container_apps    = optional(string, "10.0.16.0/21")
      private_endpoints = optional(string, "10.0.24.0/24")
    }), {
      default           = "10.0.0.0/24"
      container_apps    = "10.0.16.0/21"
      private_endpoints = "10.0.24.0/24"
    })
    enable_private_endpoints = optional(bool, false)
  })
  default = {
    address_space = ["10.0.0.0/16"]
    subnets = {
      default           = "10.0.0.0/24"
      container_apps    = "10.0.16.0/21"
      private_endpoints = "10.0.24.0/24"
    }
    enable_private_endpoints = false
  }
}

# =============================================================================
# Observability Configuration
# =============================================================================

variable "observability_config" {
  description = "Configuração de Observabilidade"
  type = object({
    retention_in_days = optional(number, 30)
  })
  default = {
    retention_in_days = 30
  }
}

# =============================================================================
# Key Vault Configuration
# =============================================================================

variable "key_vault_config" {
  description = "Configuração do Key Vault"
  type = object({
    sku_name                   = optional(string, "standard")
    purge_protection_enabled   = optional(bool, false)
    soft_delete_retention_days = optional(number, 7)
    secrets_officer_object_ids = optional(list(string), [])
    secrets                    = optional(map(string), {})
  })
  default = {
    sku_name                   = "standard"
    purge_protection_enabled   = false
    soft_delete_retention_days = 7
    secrets_officer_object_ids = []
    secrets                    = {}
  }
}

# =============================================================================
# Storage Configuration
# =============================================================================

variable "storage_config" {
  description = "Configuração do Storage Account"
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    containers               = optional(list(string), [])
  })
  default = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
    containers               = []
  }
}

# =============================================================================
# Service Bus Configuration
# =============================================================================

variable "service_bus_config" {
  description = "Configuração do Service Bus"
  type = object({
    sku = optional(string, "Standard")
    queues = optional(list(object({
      name                                    = string
      max_size_in_megabytes                   = optional(number, 1024)
      max_delivery_count                      = optional(number, 10)
      default_message_ttl                     = optional(string)
      dead_lettering_on_message_expiration    = optional(bool, true)
      requires_session                        = optional(bool, false)
      requires_duplicate_detection            = optional(bool, false)
      duplicate_detection_history_time_window = optional(string)
    })), [])
    topics = optional(list(object({
      name                                    = string
      max_size_in_megabytes                   = optional(number, 1024)
      default_message_ttl                     = optional(string)
      requires_duplicate_detection            = optional(bool, false)
      duplicate_detection_history_time_window = optional(string)
      support_ordering                        = optional(bool, false)
    })), [])
    subscriptions = optional(list(object({
      name                                 = string
      topic_name                           = string
      max_delivery_count                   = optional(number, 10)
      default_message_ttl                  = optional(string)
      dead_lettering_on_message_expiration = optional(bool, true)
      requires_session                     = optional(bool, false)
    })), [])
  })
  default = {
    sku           = "Standard"
    queues        = []
    topics        = []
    subscriptions = []
  }
}

# =============================================================================
# Event Grid Configuration
# =============================================================================

variable "event_grid_config" {
  description = "Configuração do Event Grid"
  type = object({
    subscriptions = optional(list(object({
      name                 = string
      endpoint_type        = string
      endpoint_id          = optional(string)
      storage_account_id   = optional(string)
      queue_name           = optional(string)
      webhook_url          = optional(string)
      included_event_types = list(string)
      subject_filter = optional(object({
        subject_begins_with = optional(string)
        subject_ends_with   = optional(string)
        case_sensitive      = optional(bool, false)
      }))
      advanced_filters = optional(list(object({
        type   = string
        key    = string
        values = list(string)
      })))
    })), [])
  })
  default = {
    subscriptions = []
  }
}

# =============================================================================
# SQL Configuration
# =============================================================================

variable "sql_config" {
  description = "Configuração do SQL Database"
  type = object({
    administrator_login   = optional(string, "sql_admin")
    sku_name              = optional(string, "S0")
    max_size_gb           = optional(number, 2)
    backup_retention_days = optional(number, 7)
  })
  default = {
    administrator_login   = "sql_admin"
    sku_name              = "S0"
    max_size_gb           = 2
    backup_retention_days = 7
  }
}

# =============================================================================
# Redis Configuration
# =============================================================================

variable "redis_config" {
  description = "Configuração do Redis Cache"
  type = object({
    capacity = optional(number, 0)
    family   = optional(string, "C")
    sku_name = optional(string, "Basic")
  })
  default = {
    capacity = 0
    family   = "C"
    sku_name = "Basic"
  }
}

# =============================================================================
# Container Apps Configuration
# =============================================================================

variable "container_apps_config" {
  description = "Configuração do Container Apps"
  type = object({
    apps = optional(list(object({
      name          = string
      revision_mode = optional(string, "Single")
      min_replicas  = optional(number, 0)
      max_replicas  = optional(number, 10)
      container = object({
        name   = string
        image  = string
        cpu    = number
        memory = string
        env = optional(list(object({
          name        = string
          value       = optional(string)
          secret_name = optional(string)
        })), [])
        liveness_probe = optional(object({
          port             = number
          path             = optional(string, "/health")
          transport        = optional(string, "HTTP")
          interval_seconds = optional(number, 10)
        }))
        readiness_probe = optional(object({
          port             = number
          path             = optional(string, "/ready")
          transport        = optional(string, "HTTP")
          interval_seconds = optional(number, 10)
        }))
      })
      ingress = optional(object({
        target_port                = number
        external_enabled           = optional(bool, true)
        allow_insecure_connections = optional(bool, false)
        transport                  = optional(string, "auto")
      }))
      registry = optional(object({
        server               = string
        identity             = optional(string)
        username             = optional(string)
        password_secret_name = optional(string)
      }))
      secrets = optional(list(object({
        name  = string
        value = string
      })), [])
      identity = optional(object({
        type         = string
        identity_ids = optional(list(string))
      }))
      http_scale_rule = optional(object({
        name                = string
        concurrent_requests = number
      }))
      custom_scale_rules = optional(list(object({
        name             = string
        custom_rule_type = string
        metadata         = map(string)
        authentication = optional(object({
          secret_name       = string
          trigger_parameter = string
        }))
      })), [])
    })), [])
  })
  default = {
    apps = []
  }
}
