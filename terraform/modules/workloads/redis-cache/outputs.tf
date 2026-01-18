output "id" {
  description = "ID of the Redis cache"
  value       = azurerm_redis_cache.main.id
}

output "name" {
  description = "Name of the Redis cache"
  value       = azurerm_redis_cache.main.name
}

output "hostname" {
  description = "Hostname of the Redis cache"
  value       = azurerm_redis_cache.main.hostname
}

output "port" {
  description = "Port of the Redis cache"
  value       = azurerm_redis_cache.main.port
}

output "ssl_port" {
  description = "SSL port of the Redis cache"
  value       = azurerm_redis_cache.main.ssl_port
}

output "primary_access_key" {
  description = "Primary access key for the Redis cache"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}
