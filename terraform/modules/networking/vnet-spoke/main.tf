# =============================================================================
# VNet Spoke Module
# =============================================================================

resource "azurerm_virtual_network" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "default" {
  name                 = "${var.subnet_prefix}-default"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets.default]

  service_endpoints = var.enable_service_endpoints ? [
    "Microsoft.Storage",
    "Microsoft.Sql",
    "Microsoft.ServiceBus",
    "Microsoft.KeyVault",
    "Microsoft.EventHub"
  ] : []
}

resource "azurerm_subnet" "container_apps" {
  count = var.enable_container_apps_subnet ? 1 : 0

  name                 = "${var.subnet_prefix}-container-apps"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets.container_apps]

  delegation {
    name = "container-apps-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  count = var.enable_private_endpoints_subnet ? 1 : 0

  name                 = "${var.subnet_prefix}-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets.private_endpoints]
}

resource "azurerm_network_security_group" "default" {
  count = var.enable_nsg ? 1 : 0

  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "default" {
  count = var.enable_nsg ? 1 : 0

  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.default[0].id
}
