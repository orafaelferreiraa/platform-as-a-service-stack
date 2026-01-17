output "id" {
  description = "Virtual Network resource ID"
  value       = azurerm_virtual_network.main.id
}

output "name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.main.name
}

output "address_space" {
  description = "Virtual Network address space"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_default_id" {
  description = "Default subnet ID"
  value       = azurerm_subnet.default.id
}

output "subnet_private_endpoints_id" {
  description = "Private endpoints subnet ID"
  value       = azurerm_subnet.private_endpoints.id
}

output "subnet_container_apps_id" {
  description = "Container Apps subnet ID"
  value       = try(azurerm_subnet.container_apps[0].id, null)
}

output "subnet_sql_id" {
  description = "SQL subnet ID"
  value       = try(azurerm_subnet.sql[0].id, null)
}

output "subnet_redis_id" {
  description = "Redis subnet ID"
  value       = try(azurerm_subnet.redis[0].id, null)
}
