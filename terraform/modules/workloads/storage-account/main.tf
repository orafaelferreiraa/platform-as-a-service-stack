#checkov:skip=CKV2_AZURE_1:CMK encryption requires Premium tier and dedicated encryption Key Vault - not applicable for platform Standard storage
#checkov:skip=CKV2_AZURE_21:Classic Storage Analytics logging deprecated in azurerm 4.x - using Azure Monitor Diagnostic Settings for StorageRead/Write/Delete instead
#tfsec:ignore:azure-storage-use-customer-managed-key CMK requires Premium tier - Standard storage uses Microsoft-managed keys
#tfsec:ignore:azure-storage-queue-services-logging-enabled Classic Queue Analytics logging deprecated - using Azure Monitor Diagnostic Settings instead
#tfsec:ignore:azure-storage-default-action-deny Network rules conditionally applied when VNet is enabled - GitHub-hosted runners require public access
#trivy:ignore:AVD-AZU-0057 Classic Storage Analytics logging deprecated in azurerm 4.x - using Azure Monitor Diagnostic Settings for StorageRead/Write/Delete instead
#trivy:ignore:AVD-AZU-0058 LRS is a deliberate cost-optimization choice - data can be reconstructed and no cross-region DR requirement exists
resource "azurerm_storage_account" "main" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  infrastructure_encryption_enabled = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true # Required for GitHub-hosted CI/CD runners - no static IPs for private endpoints

  # Disable key-based authentication (Azure AD only)
  shared_access_key_enabled = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Network rules (if VNet is enabled)
resource "azurerm_storage_account_network_rules" "main" {
  count                      = length(var.vnet_subnet_ids) > 0 ? 1 : 0
  storage_account_id         = azurerm_storage_account.main.id
  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = var.vnet_subnet_ids
}

# RBAC: Grant managed identity Storage Blob Data Contributor role
# Automatically created when managed_identity_id is provided - zero config
resource "azurerm_role_assignment" "managed_identity_blob_contributor" {
  count                = var.enable_managed_identity ? 1 : 0
  name                 = uuidv5("dns", "${azurerm_storage_account.main.id}-${var.managed_identity_id}-blob-contributor")
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_id
}

# Create default containers
# Note: When shared_access_key_enabled = false, containers must be created
# after the storage account is fully provisioned and RBAC is configured.
# Using depends_on to ensure proper ordering when managed identity is used.
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"

  depends_on = [azurerm_role_assignment.managed_identity_blob_contributor]
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"

  depends_on = [azurerm_role_assignment.managed_identity_blob_contributor]
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                      = var.enable_observability ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }
}
