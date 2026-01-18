resource "azurerm_servicebus_namespace" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tags                = var.tags
}

# Create a default queue
resource "azurerm_servicebus_queue" "events" {
  name         = "sbq-events"
  namespace_id = azurerm_servicebus_namespace.main.id

  dead_lettering_on_message_expiration = true
  max_delivery_count                   = 10
  default_message_ttl                  = "P14D" # 14 days
}

# Create a default topic
resource "azurerm_servicebus_topic" "events" {
  name         = "sbt-events"
  namespace_id = azurerm_servicebus_namespace.main.id

  default_message_ttl = "P14D" # 14 days
}

# Create a subscription for the topic
resource "azurerm_servicebus_subscription" "events" {
  name               = "sbts-events"
  topic_id           = azurerm_servicebus_topic.events.id
  max_delivery_count = 10
}

# RBAC: Grant managed identity Service Bus Data Sender role
resource "azurerm_role_assignment" "managed_identity_sender" {
  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = var.managed_identity_id
}

# RBAC: Grant managed identity Service Bus Data Receiver role
resource "azurerm_role_assignment" "managed_identity_receiver" {
  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = var.managed_identity_id
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                      = var.enable_observability && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_servicebus_namespace.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_log {
    category = "VNetAndIPFilteringLogs"
  }

  enabled_log {
    category = "RuntimeAuditLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
