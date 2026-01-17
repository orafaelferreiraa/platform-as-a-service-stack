# =============================================================================
# Container Apps Module - Environment + Container Apps
# =============================================================================

resource "azurerm_container_app_environment" "main" {
  name                           = var.environment_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  zone_redundancy_enabled        = var.zone_redundancy_enabled
  tags                           = var.tags
}

resource "azurerm_container_app" "apps" {
  for_each = { for app in var.container_apps : app.name => app }

  name                         = each.value.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = lookup(each.value, "revision_mode", "Single")
  tags                         = var.tags

  template {
    min_replicas = lookup(each.value, "min_replicas", 0)
    max_replicas = lookup(each.value, "max_replicas", 10)

    container {
      name   = each.value.container.name
      image  = each.value.container.image
      cpu    = each.value.container.cpu
      memory = each.value.container.memory

      dynamic "env" {
        for_each = lookup(each.value.container, "env", [])
        content {
          name        = env.value.name
          value       = lookup(env.value, "value", null)
          secret_name = lookup(env.value, "secret_name", null)
        }
      }

      dynamic "liveness_probe" {
        for_each = lookup(each.value.container, "liveness_probe", null) != null ? [each.value.container.liveness_probe] : []
        content {
          port             = liveness_probe.value.port
          path             = lookup(liveness_probe.value, "path", "/")
          transport        = lookup(liveness_probe.value, "transport", "HTTP")
          interval_seconds = lookup(liveness_probe.value, "interval_seconds", 10)
        }
      }

      dynamic "readiness_probe" {
        for_each = lookup(each.value.container, "readiness_probe", null) != null ? [each.value.container.readiness_probe] : []
        content {
          port             = readiness_probe.value.port
          path             = lookup(readiness_probe.value, "path", "/")
          transport        = lookup(readiness_probe.value, "transport", "HTTP")
          interval_seconds = lookup(readiness_probe.value, "interval_seconds", 10)
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = lookup(each.value, "http_scale_rule", null) != null ? [each.value.http_scale_rule] : []
      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.concurrent_requests
      }
    }

    dynamic "custom_scale_rule" {
      for_each = lookup(each.value, "custom_scale_rules", [])
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata
        dynamic "authentication" {
          for_each = lookup(custom_scale_rule.value, "authentication", null) != null ? [custom_scale_rule.value.authentication] : []
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }
  }

  dynamic "ingress" {
    for_each = lookup(each.value, "ingress", null) != null ? [each.value.ingress] : []
    content {
      allow_insecure_connections = lookup(ingress.value, "allow_insecure_connections", false)
      external_enabled           = lookup(ingress.value, "external_enabled", true)
      target_port                = ingress.value.target_port
      transport                  = lookup(ingress.value, "transport", "auto")

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  dynamic "registry" {
    for_each = lookup(each.value, "registry", null) != null ? [each.value.registry] : []
    content {
      server               = registry.value.server
      identity             = lookup(registry.value, "identity", null)
      username             = lookup(registry.value, "username", null)
      password_secret_name = lookup(registry.value, "password_secret_name", null)
    }
  }

  dynamic "secret" {
    for_each = lookup(each.value, "secrets", [])
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  dynamic "identity" {
    for_each = lookup(each.value, "identity", null) != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }
}
