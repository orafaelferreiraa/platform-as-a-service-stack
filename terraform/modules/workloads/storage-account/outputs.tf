# =============================================================================
# Storage Account Module - Outputs
# =============================================================================

output "id" {
  value = azurerm_storage_account.main.id
}

output "name" {
  value = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_connection_string" {
  value     = azurerm_storage_account.main.primary_connection_string
  sensitive = true
}

output "primary_access_key" {
  value     = azurerm_storage_account.main.primary_access_key
  sensitive = true
}

output "secondary_access_key" {
  value     = azurerm_storage_account.main.secondary_access_key
  sensitive = true
}

output "container_ids" {
  value = { for k, v in azurerm_storage_container.containers : k => v.id }
}
