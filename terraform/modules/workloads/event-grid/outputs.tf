output "id" {
  description = "Event Grid topic resource ID"
  value       = azurerm_eventgrid_topic.main.id
}

output "name" {
  description = "Event Grid topic name"
  value       = azurerm_eventgrid_topic.main.name
}

output "endpoint" {
  description = "Event Grid topic endpoint"
  value       = azurerm_eventgrid_topic.main.endpoint
}

output "primary_access_key" {
  description = "Primary access key for the topic"
  value       = azurerm_eventgrid_topic.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key for the topic"
  value       = azurerm_eventgrid_topic.main.secondary_access_key
  sensitive   = true
}

output "identity_principal_id" {
  description = "System assigned identity principal ID"
  value       = azurerm_eventgrid_topic.main.identity[0].principal_id
}

output "webhook_subscription_ids" {
  description = "Map of webhook subscription names to their resource IDs"
  value       = { for k, v in azurerm_eventgrid_event_subscription.webhook : k => v.id }
}

output "service_bus_queue_subscription_ids" {
  description = "Map of Service Bus queue subscription names to their resource IDs"
  value       = { for k, v in azurerm_eventgrid_event_subscription.service_bus_queue : k => v.id }
}

output "service_bus_topic_subscription_ids" {
  description = "Map of Service Bus topic subscription names to their resource IDs"
  value       = { for k, v in azurerm_eventgrid_event_subscription.service_bus_topic : k => v.id }
}

output "storage_queue_subscription_ids" {
  description = "Map of storage queue subscription names to their resource IDs"
  value       = { for k, v in azurerm_eventgrid_event_subscription.storage_queue : k => v.id }
}
