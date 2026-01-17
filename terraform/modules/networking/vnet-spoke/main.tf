# Networking Module: VNet Spoke
# Creates a Virtual Network with subnets for platform services

resource "azurerm_virtual_network" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  tags = var.tags
}

# Default subnet for general workloads
resource "azurerm_subnet" "default" {
  name                 = "snet-default"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets.default]
}

# Subnet for private endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets.private_endpoints]
}

# Subnet for Container Apps Environment
resource "azurerm_subnet" "container_apps" {
  count = var.subnets.container_apps != null ? 1 : 0

  name                 = "snet-container-apps"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets.container_apps]

  delegation {
    name = "delegation-container-apps"

    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Subnet for SQL Server (optional)
resource "azurerm_subnet" "sql" {
  count = var.subnets.sql != null ? 1 : 0

  name                 = "snet-sql"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets.sql]

  service_endpoints = ["Microsoft.Sql"]
}

# Subnet for Redis Cache (optional)
resource "azurerm_subnet" "redis" {
  count = var.subnets.redis != null ? 1 : 0

  name                 = "snet-redis"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets.redis]
}
