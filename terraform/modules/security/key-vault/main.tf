#checkov:skip=CKV_AZURE_189:Public network access required for GitHub-hosted CI/CD runners
#checkov:skip=CKV_AZURE_109:Network ACL default deny not possible with GitHub-hosted CI/CD runners
#checkov:skip=CKV2_AZURE_32:Private endpoint not possible with GitHub-hosted CI/CD runners - no static IP for runner VNet integration
#tfsec:ignore:azure-keyvault-specify-network-acl Network ACL default deny not possible with GitHub-hosted CI/CD runners - no static IPs for VNet integration
resource "azurerm_key_vault" "main" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  rbac_authorization_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# RBAC: Grant current service principal Key Vault Administrator role
# Using uuidv5 with static values to ensure deterministic role assignment name
resource "azurerm_role_assignment" "current_admin" {
  name                 = uuidv5("dns", "${azurerm_key_vault.main.id}-${var.current_principal_id}-admin")
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.current_principal_id
}

# Wait for RBAC propagation (Azure RBAC can take up to 5 minutes to propagate)
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.current_admin]
  create_duration = "180s"

  # Re-trigger sleep if the role assignment changes
  triggers = {
    role_assignment_id = azurerm_role_assignment.current_admin.id
  }
}

# RBAC: Grant managed identity Key Vault Secrets User role
# Automatically created when managed_identity_id is provided - zero config
resource "azurerm_role_assignment" "managed_identity_secrets_user" {
  count                = var.enable_managed_identity ? 1 : 0
  name                 = uuidv5("dns", "${azurerm_key_vault.main.id}-${var.managed_identity_id}-secrets-user")
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.managed_identity_id
}

# Create secrets
#checkov:skip=CKV_AZURE_41:Secret expiration managed via lifecycle ignore - rotated by platform operations
resource "azurerm_key_vault_secret" "secrets" {
  for_each        = var.secrets
  name            = each.key
  value           = each.value
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "text/plain"
  expiration_date = timeadd(plantimestamp(), "8760h")

  lifecycle {
    ignore_changes = [expiration_date]
  }

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
