# Workload Module: Redis Cache
# Creates Azure Cache for Redis
# NOTE: redis_persistence block and enable_authentication are NOT supported in provider 4.x

resource "azurerm_redis_cache" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  capacity             = var.capacity
  family               = var.family
  sku_name             = var.sku_name
  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  # Redis configuration
  redis_configuration {
    aof_backup_enabled              = var.sku_name == "Premium" ? var.aof_backup_enabled : null
    aof_storage_connection_string_0 = var.sku_name == "Premium" && var.aof_backup_enabled ? var.aof_storage_connection_string : null
    maxmemory_policy                = var.maxmemory_policy
    maxmemory_reserved              = var.maxmemory_reserved
    maxmemory_delta                 = var.maxmemory_delta
    notify_keyspace_events          = var.notify_keyspace_events
  }

  # VNet integration for Premium SKU
  subnet_id = var.sku_name == "Premium" ? var.subnet_id : null

  # Replicas for Premium SKU
  replicas_per_master = var.sku_name == "Premium" ? var.replicas_per_master : null

  # Identity
  dynamic "identity" {
    for_each = var.managed_identity_id != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.managed_identity_id]
    }
  }

  tags = var.tags
}
