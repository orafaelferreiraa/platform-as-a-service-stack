resource "azurerm_eventgrid_domain" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Create a topic within the domain
resource "azurerm_eventgrid_domain_topic" "events" {
  name                = "evgt-events"
  domain_name         = azurerm_eventgrid_domain.main.name
  resource_group_name = var.resource_group_name
}

# Create event subscription to Service Bus topic (if enabled)
resource "azurerm_eventgrid_event_subscription" "service_bus" {
  count = try(var.service_bus_topic_id != null && var.service_bus_topic_id != "", false) ? 1 : 0
  name  = "evgs-servicebus"
  scope = azurerm_eventgrid_domain.main.id

  service_bus_topic_endpoint_id = var.service_bus_topic_id

  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440
  }
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                      = var.enable_observability ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_eventgrid_domain.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "DeliveryFailures"
  }

  enabled_log {
    category = "PublishFailures"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
