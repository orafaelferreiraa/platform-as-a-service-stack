data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = var.tags
}

# RBAC: Grant current service principal Key Vault Administrator role
resource "azurerm_role_assignment" "current_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Wait for RBAC propagation (Azure RBAC can take up to 5 minutes to propagate)
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.current_admin]
  create_duration = "90s"
}

# RBAC: Grant managed identity Key Vault Secrets User role
resource "azurerm_role_assignment" "managed_identity_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.managed_identity_id
}

# Create secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [time_sleep.wait_for_rbac]
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                      = var.enable_observability ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
