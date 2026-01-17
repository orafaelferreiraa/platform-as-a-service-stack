# Workload Module: Storage Account
# Creates an Azure Storage Account with best practices for security

resource "azurerm_storage_account" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind

  # Security settings - Use correct attribute for provider 4.x
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = var.shared_access_key_enabled

  # Identity
  identity {
    type         = var.managed_identity_id != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.managed_identity_id != null ? [var.managed_identity_id] : []
  }

  # Network rules (optional)
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  # Blob properties
  blob_properties {
    versioning_enabled = var.enable_versioning

    dynamic "delete_retention_policy" {
      for_each = var.soft_delete_retention_days > 0 ? [1] : []
      content {
        days = var.soft_delete_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.container_soft_delete_retention_days > 0 ? [1] : []
      content {
        days = var.container_soft_delete_retention_days
      }
    }
  }

  tags = var.tags
}

# RBAC assignment for managed identity
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  count = var.managed_identity_principal_id != null ? 1 : 0

  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_principal_id
}
