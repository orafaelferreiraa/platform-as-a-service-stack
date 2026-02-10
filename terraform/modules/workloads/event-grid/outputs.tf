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

output "topic_id" {
  description = "ID of the Event Grid domain topic"
  value       = azurerm_eventgrid_domain_topic.events.id
}
