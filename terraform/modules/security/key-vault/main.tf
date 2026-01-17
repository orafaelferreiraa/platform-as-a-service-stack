# =============================================================================
# Key Vault Module - Azure Key Vault com RBAC
# =============================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  soft_delete_retention_days   = var.soft_delete_retention_days
  purge_protection_enabled     = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.enable_network_acls ? [1] : []
    content {
      default_action             = var.network_default_action
      bypass                     = "AzureServices"
      ip_rules                   = var.allowed_ip_ranges
      virtual_network_subnet_ids = var.allowed_subnet_ids
    }
  }

  tags = var.tags
}

# =============================================================================
# RBAC Assignments
# =============================================================================

resource "azurerm_role_assignment" "secrets_user" {
  for_each = var.secrets_user_principal_ids

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "secrets_officer" {
  for_each = var.secrets_officer_principal_ids

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}

# =============================================================================
# Secrets
# =============================================================================

resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.secrets_officer]
}
