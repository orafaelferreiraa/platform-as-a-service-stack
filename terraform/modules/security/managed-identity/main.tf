# Security Module: Managed Identity
# Creates a User Assigned Managed Identity for platform resources

resource "azurerm_user_assigned_identity" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
