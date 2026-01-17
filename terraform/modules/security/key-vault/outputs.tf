# =============================================================================
# Key Vault Module - Outputs
# NOTA: NUNCA expor valores de secrets nos outputs
# =============================================================================

output "id" {
  value = azurerm_key_vault.main.id
}

output "name" {
  value = azurerm_key_vault.main.name
}

output "vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "tenant_id" {
  value = azurerm_key_vault.main.tenant_id
}

output "secret_ids" {
  description = "IDs dos secrets criados (sem valores)"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_uris" {
  description = "URIs dos secrets (para referência em outros recursos)"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.versionless_id }
}

output "secret_names" {
  value = { for k, v in azurerm_key_vault_secret.secrets : k => v.name }
}
