# =============================================================================
# Observability Module - Outputs
# =============================================================================

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_primary_key" {
  value     = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive = true
}

output "log_analytics_workspace_secondary_key" {
  value     = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive = true
}

output "app_insights_id" {
  value = azurerm_application_insights.main.id
}

output "app_insights_name" {
  value = azurerm_application_insights.main.name
}

output "app_insights_instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

output "app_insights_connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}

output "app_insights_app_id" {
  value = azurerm_application_insights.main.app_id
}
