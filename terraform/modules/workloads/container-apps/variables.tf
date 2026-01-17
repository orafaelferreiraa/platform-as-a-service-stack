# =============================================================================
# Container Apps Module - Variables
# =============================================================================

variable "environment_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "infrastructure_subnet_id" {
  type    = string
  default = null
}

variable "internal_load_balancer_enabled" {
  type    = bool
  default = false
}

variable "zone_redundancy_enabled" {
  type    = bool
  default = false
}

variable "container_apps" {
  type = list(object({
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
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
