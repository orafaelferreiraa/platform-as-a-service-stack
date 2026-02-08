resource "azurerm_eventgrid_domain" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = false
  local_auth_enabled            = false

  dynamic "identity" {
    for_each = var.managed_identity_id != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.managed_identity_id]
    }
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
  count = var.enable_service_bus_integration ? 1 : 0
  name  = "evgs-servicebus"
  scope = azurerm_eventgrid_domain.main.id

  service_bus_topic_endpoint_id = var.service_bus_topic_id

  # Use User-Assigned MI for authenticated delivery to Service Bus
  dynamic "delivery_identity" {
    for_each = var.managed_identity_id != null ? [1] : []
    content {
      type                   = "UserAssigned"
      user_assigned_identity = var.managed_identity_id
    }
  }

  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440
  }
}

# RBAC: Grant managed identity EventGrid Data Sender role
# Allows apps using the MI to publish events to Event Grid domain
resource "azurerm_role_assignment" "managed_identity_eventgrid_sender" {
  count                = var.enable_managed_identity ? 1 : 0
  name                 = uuidv5("dns", "${azurerm_eventgrid_domain.main.id}-${var.managed_identity_principal_id}-eventgrid-sender")
  scope                = azurerm_eventgrid_domain.main.id
  role_definition_name = "EventGrid Data Sender"
  principal_id         = var.managed_identity_principal_id
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
