# Security Module: Key Vault
# Creates an Azure Key Vault with RBAC authorization (default in provider 4.x)

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # Security settings
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled

  # Network settings
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      default_action             = network_acls.value.default_action
      bypass                     = network_acls.value.bypass
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}

# Create secrets from the sensitive secrets map
# Using nonsensitive(keys()) to iterate while keeping values sensitive
resource "azurerm_key_vault_secret" "secrets" {
  for_each = { for k in nonsensitive(keys(var.secrets)) : k => var.secrets[k] }

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}

# RBAC assignment for the deployer to manage secrets
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC assignment for managed identity (if provided)
resource "azurerm_role_assignment" "managed_identity_secrets_user" {
  count = var.managed_identity_principal_id != null ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.managed_identity_principal_id
}
