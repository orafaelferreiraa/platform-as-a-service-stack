output "id" {
  description = "ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.id
}

output "name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.name
}

output "default_domain" {
  description = "Default domain of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.default_domain
}

output "static_ip_address" {
  description = "Static IP address of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.static_ip_address
}

output "managed_identity_id" {
  description = "Resource ID of the User-Assigned Managed Identity attached to this environment (null if not configured)"
  value       = var.managed_identity_id
}

output "container_registry_login_server" {
  description = "Login server URL of the pre-configured Container Registry (null if not configured)"
  value       = var.container_registry_login_server
}
