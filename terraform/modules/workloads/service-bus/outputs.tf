output "namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.id
}

output "namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.name
}

output "queue_id" {
  description = "ID of the Service Bus queue"
  value       = azurerm_servicebus_queue.events.id
}

output "topic_id" {
  description = "ID of the Service Bus topic"
  value       = azurerm_servicebus_topic.events.id
}

output "subscription_id" {
  description = "ID of the Service Bus subscription"
  value       = azurerm_servicebus_subscription.events.id
}
