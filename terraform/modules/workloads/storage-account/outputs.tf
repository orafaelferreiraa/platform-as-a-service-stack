output "id" {
  description = "Storage account resource ID"
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_queue_endpoint" {
  description = "Primary queue endpoint"
  value       = azurerm_storage_account.main.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "Primary table endpoint"
  value       = azurerm_storage_account.main.primary_table_endpoint
}

output "primary_file_endpoint" {
  description = "Primary file endpoint"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "identity_principal_id" {
  description = "System assigned identity principal ID"
  value       = azurerm_storage_account.main.identity[0].principal_id
}
