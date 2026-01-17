# Workload Module: Container Apps
# Creates Azure Container Apps Environment and apps

resource "azurerm_container_app_environment" "main" {
  name                       = var.environment_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # VNet integration (optional)
  infrastructure_subnet_id = var.subnet_id

  # Internal/external load balancer
  internal_load_balancer_enabled = var.internal_load_balancer_enabled

  tags = var.tags
}

# Container Apps
resource "azurerm_container_app" "apps" {
  for_each = var.container_apps

  name                         = each.key
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = each.value.revision_mode

  # Managed identity
  identity {
    type         = var.managed_identity_id != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.managed_identity_id != null ? [var.managed_identity_id] : []
  }

  # Container template
  template {
    dynamic "container" {
      for_each = each.value.containers
      content {
        name   = container.value.name
        image  = container.value.image
        cpu    = container.value.cpu
        memory = container.value.memory

        dynamic "env" {
          for_each = container.value.env != null ? container.value.env : {}
          content {
            name        = env.key
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }
      }
    }

    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas

    dynamic "http_scale_rule" {
      for_each = each.value.http_scale_rule != null ? [each.value.http_scale_rule] : []
      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.concurrent_requests
      }
    }
  }

  # Ingress configuration
  dynamic "ingress" {
    for_each = each.value.ingress != null ? [each.value.ingress] : []
    content {
      external_enabled = ingress.value.external_enabled
      target_port      = ingress.value.target_port
      transport        = ingress.value.transport

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  # Secrets
  dynamic "secret" {
    for_each = each.value.secrets != null ? each.value.secrets : {}
    content {
      name  = secret.key
      value = secret.value
    }
  }

  # Registry
  dynamic "registry" {
    for_each = each.value.registry != null ? [each.value.registry] : []
    content {
      server               = registry.value.server
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
      identity             = registry.value.identity
    }
  }

  tags = var.tags
}
