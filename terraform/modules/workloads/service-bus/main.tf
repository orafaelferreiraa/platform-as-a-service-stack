#checkov:skip=CKV_AZURE_199:Double encryption requires Premium SKU - using Standard for cost optimization
#checkov:skip=CKV_AZURE_201:Customer-managed key requires Premium SKU - using Standard for cost optimization
#tfsec:ignore:azure-servicebus-use-customer-managed-key CMK requires Premium SKU - using Standard for cost optimization
resource "azurerm_servicebus_namespace" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  local_auth_enabled            = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true # Required for GitHub-hosted CI/CD runners - no static IPs for private endpoints
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    prevent_destroy = true
  }
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
# Automatically created when managed_identity_id is provided - zero config
resource "azurerm_role_assignment" "managed_identity_sender" {
  count                = var.managed_identity_id != null ? 1 : 0
  name                 = uuidv5("dns", "${azurerm_servicebus_namespace.main.id}-${var.managed_identity_id}-sender")
  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = var.managed_identity_id
}

# RBAC: Grant managed identity Service Bus Data Receiver role
# Automatically created when managed_identity_id is provided - zero config
resource "azurerm_role_assignment" "managed_identity_receiver" {
  count                = var.managed_identity_id != null ? 1 : 0
  name                 = uuidv5("dns", "${azurerm_servicebus_namespace.main.id}-${var.managed_identity_id}-receiver")
  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = var.managed_identity_id
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                      = var.enable_observability ? 1 : 0
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
