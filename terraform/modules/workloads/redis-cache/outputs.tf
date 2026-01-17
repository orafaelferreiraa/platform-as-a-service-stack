# =============================================================================
# Redis Cache Module - Outputs
# =============================================================================

output "id" {
  value = azurerm_redis_cache.main.id
}

output "name" {
  value = azurerm_redis_cache.main.name
}

output "hostname" {
  value = azurerm_redis_cache.main.hostname
}

output "port" {
  value = azurerm_redis_cache.main.port
}

output "ssl_port" {
  value = azurerm_redis_cache.main.ssl_port
}

output "primary_access_key" {
  value     = azurerm_redis_cache.main.primary_access_key
  sensitive = true
}

output "secondary_access_key" {
  value     = azurerm_redis_cache.main.secondary_access_key
  sensitive = true
}

output "primary_connection_string" {
  value     = azurerm_redis_cache.main.primary_connection_string
  sensitive = true
}

output "secondary_connection_string" {
  value     = azurerm_redis_cache.main.secondary_connection_string
  sensitive = true
}
