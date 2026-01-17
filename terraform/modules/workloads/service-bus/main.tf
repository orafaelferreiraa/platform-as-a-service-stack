# =============================================================================
# Service Bus Module
# =============================================================================

resource "azurerm_servicebus_namespace" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? var.capacity : 0
  premium_messaging_partitions  = var.sku == "Premium" ? var.premium_messaging_partitions : 0
  local_auth_enabled            = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = var.minimum_tls_version
  tags                          = var.tags
}

resource "azurerm_servicebus_queue" "queues" {
  for_each = { for q in var.queues : q.name => q }

  name                                    = each.value.name
  namespace_id                            = azurerm_servicebus_namespace.main.id
  max_size_in_megabytes                   = lookup(each.value, "max_size_in_megabytes", 1024)
  default_message_ttl                     = lookup(each.value, "default_message_ttl", null)
  lock_duration                           = lookup(each.value, "lock_duration", "PT1M")
  max_delivery_count                      = lookup(each.value, "max_delivery_count", 10)
  dead_lettering_on_message_expiration    = lookup(each.value, "dead_lettering_on_message_expiration", true)
  partitioning_enabled                    = lookup(each.value, "partitioning_enabled", false)
  requires_duplicate_detection            = lookup(each.value, "requires_duplicate_detection", false)
  duplicate_detection_history_time_window = lookup(each.value, "duplicate_detection_history_time_window", null)
  requires_session                        = lookup(each.value, "requires_session", false)
}

resource "azurerm_servicebus_topic" "topics" {
  for_each = { for t in var.topics : t.name => t }

  name                                    = each.value.name
  namespace_id                            = azurerm_servicebus_namespace.main.id
  max_size_in_megabytes                   = lookup(each.value, "max_size_in_megabytes", 1024)
  default_message_ttl                     = lookup(each.value, "default_message_ttl", null)
  partitioning_enabled                    = lookup(each.value, "partitioning_enabled", false)
  requires_duplicate_detection            = lookup(each.value, "requires_duplicate_detection", false)
  duplicate_detection_history_time_window = lookup(each.value, "duplicate_detection_history_time_window", null)
  support_ordering                        = lookup(each.value, "support_ordering", false)
}

resource "azurerm_servicebus_subscription" "subscriptions" {
  for_each = { for s in var.subscriptions : "${s.topic_name}-${s.name}" => s }

  name                                 = each.value.name
  topic_id                             = azurerm_servicebus_topic.topics[each.value.topic_name].id
  max_delivery_count                   = lookup(each.value, "max_delivery_count", 10)
  default_message_ttl                  = lookup(each.value, "default_message_ttl", null)
  lock_duration                        = lookup(each.value, "lock_duration", "PT1M")
  dead_lettering_on_message_expiration = lookup(each.value, "dead_lettering_on_message_expiration", true)
  requires_session                     = lookup(each.value, "requires_session", false)
}

resource "azurerm_role_assignment" "data_owner" {
  count = var.identity_principal_id != null ? 1 : 0

  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = var.identity_principal_id
}
