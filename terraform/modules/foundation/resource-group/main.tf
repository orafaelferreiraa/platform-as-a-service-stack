# Foundation Module: Resource Group
# Creates the main resource group for the platform

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
