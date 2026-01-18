resource "azurerm_storage_account" "main" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  account_kind               = "StorageV2"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

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
resource "azurerm_role_assignment" "managed_identity_blob_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_id
}

# Create default containers
resource "azurerm_storage_container" "data" {
  name                   = "data"
  storage_account_id     = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                   = "logs"
  storage_account_id     = azurerm_storage_account.main.id
  container_access_type = "private"
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
