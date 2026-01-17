# =============================================================================
# Redis Cache Module
# =============================================================================

resource "azurerm_redis_cache" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  non_ssl_port_enabled          = var.non_ssl_port_enabled
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled
  redis_version                 = var.redis_version
  tags                          = var.tags

  redis_configuration {
    aof_backup_enabled              = var.aof_backup_enabled
    aof_storage_connection_string_0 = var.aof_storage_connection_string_0
    aof_storage_connection_string_1 = var.aof_storage_connection_string_1
    maxmemory_reserved              = var.maxmemory_reserved
    maxmemory_delta                 = var.maxmemory_delta
    maxmemory_policy                = var.maxmemory_policy
    notify_keyspace_events          = var.notify_keyspace_events
    rdb_backup_enabled              = var.rdb_backup_enabled
    rdb_backup_frequency            = var.rdb_backup_frequency
    rdb_backup_max_snapshot_count   = var.rdb_backup_max_snapshot_count
    rdb_storage_connection_string   = var.rdb_storage_connection_string
  }
}

resource "azurerm_role_assignment" "contributor" {
  count = var.identity_principal_id != null ? 1 : 0

  scope                = azurerm_redis_cache.main.id
  role_definition_name = "Redis Cache Contributor"
  principal_id         = var.identity_principal_id
}
