# =============================================================================
# VNet Spoke Module - Outputs
# =============================================================================

output "id" {
  value = azurerm_virtual_network.main.id
}

output "name" {
  value = azurerm_virtual_network.main.name
}

output "address_space" {
  value = azurerm_virtual_network.main.address_space
}

output "default_subnet_id" {
  value = azurerm_subnet.default.id
}

output "default_subnet_name" {
  value = azurerm_subnet.default.name
}

output "container_apps_subnet_id" {
  value = var.enable_container_apps_subnet ? azurerm_subnet.container_apps[0].id : null
}

output "container_apps_subnet_name" {
  value = var.enable_container_apps_subnet ? azurerm_subnet.container_apps[0].name : null
}

output "private_endpoints_subnet_id" {
  value = var.enable_private_endpoints_subnet ? azurerm_subnet.private_endpoints[0].id : null
}

output "nsg_id" {
  value = var.enable_nsg ? azurerm_network_security_group.default[0].id : null
}

output "nsg_name" {
  value = var.enable_nsg ? azurerm_network_security_group.default[0].name : null
}
