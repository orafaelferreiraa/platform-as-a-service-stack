# =============================================================================
# Event Grid Module - Outputs
# =============================================================================

output "system_topic_id" {
  value = azurerm_eventgrid_system_topic.main.id
}

output "system_topic_name" {
  value = azurerm_eventgrid_system_topic.main.name
}

output "metric_arm_resource_id" {
  value = azurerm_eventgrid_system_topic.main.metric_arm_resource_id
}

output "service_bus_queue_subscription_ids" {
  value = { for k, v in azurerm_eventgrid_system_topic_event_subscription.service_bus_queue : k => v.id }
}

output "service_bus_topic_subscription_ids" {
  value = { for k, v in azurerm_eventgrid_system_topic_event_subscription.service_bus_topic : k => v.id }
}

output "storage_queue_subscription_ids" {
  value = { for k, v in azurerm_eventgrid_system_topic_event_subscription.storage_queue : k => v.id }
}

output "webhook_subscription_ids" {
  value = { for k, v in azurerm_eventgrid_system_topic_event_subscription.webhook : k => v.id }
}
