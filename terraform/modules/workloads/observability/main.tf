resource "azurerm_log_analytics_workspace" "main" {
  name                = var.naming.log_analytics_workspace
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags

  dynamic "identity" {
    for_each = var.managed_identity_resource_id != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.managed_identity_resource_id]
    }
  }
}

resource "azurerm_application_insights" "main" {
  name                = var.naming.application_insights
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}
