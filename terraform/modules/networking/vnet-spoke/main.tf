locals {
  subnet_default_name        = "snet-default-${var.name}"
  subnet_container_apps_name = coalesce(var.container_apps_subnet_name, "snet-ca-${var.name}")
  nsg_name                   = "nsg-${var.name}"
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = local.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

# Default Subnet
resource "azurerm_subnet" "default" {
  name                 = local.subnet_default_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.default_subnet_prefix]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Sql",
    "Microsoft.KeyVault"
  ]
}

# Container Apps Subnet (requires delegation)
resource "azurerm_subnet" "container_apps" {
  name                 = local.subnet_container_apps_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.container_apps_subnet_prefix]

  delegation {
    name = "Microsoft.App.environments"

    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Associate NSG with default subnet
resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.main.id
}
