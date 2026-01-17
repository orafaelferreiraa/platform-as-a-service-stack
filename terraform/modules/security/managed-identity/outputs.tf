output "id" {
  description = "Managed Identity resource ID"
  value       = azurerm_user_assigned_identity.main.id
}

output "principal_id" {
  description = "Principal ID of the Managed Identity"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "client_id" {
  description = "Client ID of the Managed Identity"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "tenant_id" {
  description = "Tenant ID of the Managed Identity"
  value       = azurerm_user_assigned_identity.main.tenant_id
}

output "name" {
  description = "Name of the Managed Identity"
  value       = azurerm_user_assigned_identity.main.name
}
