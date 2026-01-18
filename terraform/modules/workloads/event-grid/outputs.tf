output "domain_id" {
  description = "ID of the Event Grid domain"
  value       = azurerm_eventgrid_domain.main.id
}

output "domain_name" {
  description = "Name of the Event Grid domain"
  value       = azurerm_eventgrid_domain.main.name
}

output "domain_endpoint" {
  description = "Endpoint of the Event Grid domain"
  value       = azurerm_eventgrid_domain.main.endpoint
}

output "domain_primary_access_key" {
  description = "Primary access key for the Event Grid domain"
  value       = azurerm_eventgrid_domain.main.primary_access_key
  sensitive   = true
}

output "topic_id" {
  description = "ID of the Event Grid domain topic"
  value       = azurerm_eventgrid_domain_topic.events.id
}
