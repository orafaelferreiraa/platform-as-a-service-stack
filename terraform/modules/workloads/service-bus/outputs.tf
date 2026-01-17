# =============================================================================
# Service Bus Module - Outputs
# =============================================================================

output "id" {
  value = azurerm_servicebus_namespace.main.id
}

output "name" {
  value = azurerm_servicebus_namespace.main.name
}

output "endpoint" {
  value = azurerm_servicebus_namespace.main.endpoint
}

output "default_primary_connection_string" {
  value     = azurerm_servicebus_namespace.main.default_primary_connection_string
  sensitive = true
}

output "default_primary_key" {
  value     = azurerm_servicebus_namespace.main.default_primary_key
  sensitive = true
}

output "queue_ids" {
  value = { for k, v in azurerm_servicebus_queue.queues : k => v.id }
}

output "topic_ids" {
  value = { for k, v in azurerm_servicebus_topic.topics : k => v.id }
}

output "subscription_ids" {
  value = { for k, v in azurerm_servicebus_subscription.subscriptions : k => v.id }
}
