resource "azurerm_container_app_environment" "main" {
  name                           = var.name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.infrastructure_subnet_id != null ? var.internal_load_balancer_enabled : false

  # Required for VNet integration with delegated subnet - only add when using VNet
  dynamic "workload_profile" {
    for_each = var.infrastructure_subnet_id != null ? [1] : []
    content {
      name                  = "Consumption"
      workload_profile_type = "Consumption"
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to workload_profile to prevent unnecessary recreation
      workload_profile
    ]
  }
}
