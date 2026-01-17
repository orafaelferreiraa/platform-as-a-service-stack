output "id" {
  description = "Redis Cache resource ID"
  value       = azurerm_redis_cache.main.id
}

output "name" {
  description = "Redis Cache name"
  value       = azurerm_redis_cache.main.name
}

output "hostname" {
  description = "Redis Cache hostname"
  value       = azurerm_redis_cache.main.hostname
}

output "port" {
  description = "Redis Cache SSL port"
  value       = azurerm_redis_cache.main.ssl_port
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key"
  value       = azurerm_redis_cache.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_redis_cache.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary connection string"
  value       = azurerm_redis_cache.main.secondary_connection_string
  sensitive   = true
}
