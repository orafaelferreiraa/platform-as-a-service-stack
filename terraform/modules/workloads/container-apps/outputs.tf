output "environment_id" {
  description = "Container Apps Environment resource ID"
  value       = azurerm_container_app_environment.main.id
}

output "environment_name" {
  description = "Container Apps Environment name"
  value       = azurerm_container_app_environment.main.name
}

output "default_domain" {
  description = "Default domain for the Container Apps Environment"
  value       = azurerm_container_app_environment.main.default_domain
}

output "static_ip_address" {
  description = "Static IP address of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.static_ip_address
}

output "app_ids" {
  description = "Map of container app names to their resource IDs"
  value       = { for k, v in azurerm_container_app.apps : k => v.id }
}

output "app_fqdns" {
  description = "Map of container app names to their FQDNs"
  value       = { for k, v in azurerm_container_app.apps : k => try(v.ingress[0].fqdn, null) }
}

output "app_identities" {
  description = "Map of container app names to their identity principal IDs"
  value       = { for k, v in azurerm_container_app.apps : k => v.identity[0].principal_id }
}
