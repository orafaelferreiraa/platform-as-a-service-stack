# Workload Module: Service Bus
# Creates an Azure Service Bus namespace with queues and topics

resource "azurerm_servicebus_namespace" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  # Premium tier specific settings
  capacity                     = var.sku == "Premium" ? var.capacity : null
  premium_messaging_partitions = var.sku == "Premium" ? var.premium_messaging_partitions : null

  # Security settings
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = "1.2"

  # Identity
  identity {
    type         = var.managed_identity_id != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.managed_identity_id != null ? [var.managed_identity_id] : []
  }

  tags = var.tags
}

# Queues
resource "azurerm_servicebus_queue" "queues" {
  for_each = var.queues

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.main.id

  max_delivery_count                   = each.value.max_delivery_count
  lock_duration                        = each.value.lock_duration
  max_size_in_megabytes                = each.value.max_size_in_megabytes
  dead_lettering_on_message_expiration = each.value.dead_lettering_on_message_expiration
  requires_duplicate_detection         = each.value.requires_duplicate_detection
  requires_session                     = each.value.requires_session
  default_message_ttl                  = each.value.default_message_ttl
}

# Topics
resource "azurerm_servicebus_topic" "topics" {
  for_each = var.topics

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.main.id

  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  support_ordering                        = each.value.support_ordering
  default_message_ttl                     = each.value.default_message_ttl
  auto_delete_on_idle                     = each.value.auto_delete_on_idle
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
}

# Topic Subscriptions
resource "azurerm_servicebus_subscription" "subscriptions" {
  for_each = var.subscriptions

  name     = each.value.name
  topic_id = azurerm_servicebus_topic.topics[each.value.topic_name].id

  max_delivery_count                   = each.value.max_delivery_count
  lock_duration                        = each.value.lock_duration
  dead_lettering_on_message_expiration = each.value.dead_lettering_on_message_expiration
  requires_session                     = each.value.requires_session
  default_message_ttl                  = each.value.default_message_ttl
}

# RBAC assignment for managed identity
resource "azurerm_role_assignment" "servicebus_data_owner" {
  count = var.managed_identity_principal_id != null ? 1 : 0

  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = var.managed_identity_principal_id
}
