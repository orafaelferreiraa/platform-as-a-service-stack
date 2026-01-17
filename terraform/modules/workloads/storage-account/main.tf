# =============================================================================
# Storage Account Module
# =============================================================================

resource "azurerm_storage_account" "main" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  account_kind                    = var.account_kind
  https_traffic_only_enabled      = var.https_traffic_only_enabled
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_public_access
  tags                            = var.tags

  dynamic "blob_properties" {
    for_each = var.enable_blob_properties ? [1] : []
    content {
      versioning_enabled = var.enable_versioning

      dynamic "container_delete_retention_policy" {
        for_each = var.container_delete_retention_days > 0 ? [1] : []
        content {
          days = var.container_delete_retention_days
        }
      }

      dynamic "delete_retention_policy" {
        for_each = var.blob_delete_retention_days > 0 ? [1] : []
        content {
          days = var.blob_delete_retention_days
        }
      }
    }
  }

  dynamic "network_rules" {
    for_each = var.enable_network_rules ? [1] : []
    content {
      default_action             = var.network_rules_default_action
      ip_rules                   = var.network_rules_ip_rules
      virtual_network_subnet_ids = var.network_rules_subnet_ids
      bypass                     = var.network_rules_bypass
    }
  }
}

resource "azurerm_storage_container" "containers" {
  for_each = toset(var.containers)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "blob_contributor" {
  count = var.identity_principal_id != null ? 1 : 0

  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.identity_principal_id
}
