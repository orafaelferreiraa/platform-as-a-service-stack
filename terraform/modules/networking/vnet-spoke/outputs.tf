output "id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "default_subnet_id" {
  description = "ID of the default subnet"
  value       = azurerm_subnet.default.id
}

output "default_subnet_name" {
  description = "Name of the default subnet"
  value       = azurerm_subnet.default.name
}

output "container_apps_subnet_id" {
  description = "ID of the Container Apps subnet"
  value       = azurerm_subnet.container_apps.id
}

output "container_apps_subnet_name" {
  description = "Name of the Container Apps subnet"
  value       = azurerm_subnet.container_apps.name
}

output "nsg_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.main.id
}
