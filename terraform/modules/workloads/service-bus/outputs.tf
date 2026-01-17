output "id" {
  description = "Service Bus namespace resource ID"
  value       = azurerm_servicebus_namespace.main.id
}

output "name" {
  description = "Service Bus namespace name"
  value       = azurerm_servicebus_namespace.main.name
}

output "endpoint" {
  description = "Service Bus namespace endpoint"
  value       = azurerm_servicebus_namespace.main.endpoint
}

output "identity_principal_id" {
  description = "System assigned identity principal ID"
  value       = azurerm_servicebus_namespace.main.identity[0].principal_id
}

output "queue_ids" {
  description = "Map of queue names to their resource IDs"
  value       = { for k, v in azurerm_servicebus_queue.queues : k => v.id }
}

output "topic_ids" {
  description = "Map of topic names to their resource IDs"
  value       = { for k, v in azurerm_servicebus_topic.topics : k => v.id }
}

output "subscription_ids" {
  description = "Map of subscription keys to their resource IDs"
  value       = { for k, v in azurerm_servicebus_subscription.subscriptions : k => v.id }
}
