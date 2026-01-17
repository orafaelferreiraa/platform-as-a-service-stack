# IMPORTANT: This module NEVER exposes secret values in outputs
# Only metadata (IDs, names, URIs) are exposed
# Applications must retrieve secret values via Key Vault URI at runtime

output "id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.main.id
}

output "name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "vault_uri" {
  description = "Key Vault URI (use this to retrieve secrets at runtime)"
  value       = azurerm_key_vault.main.vault_uri
}

output "tenant_id" {
  description = "Tenant ID where Key Vault is created"
  value       = azurerm_key_vault.main.tenant_id
}

output "secret_ids" {
  description = "Map of secret names to their resource IDs (NOT values)"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_uris" {
  description = "Map of secret names to their versionless URIs (for reference in other resources)"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.versionless_id }
}
