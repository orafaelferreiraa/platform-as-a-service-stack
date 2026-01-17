output "log_analytics_id" {
  description = "Log Analytics workspace resource ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (GUID)"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_analytics_primary_shared_key" {
  description = "Primary shared key for Log Analytics"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "app_insights_id" {
  description = "Application Insights resource ID"
  value       = azurerm_application_insights.main.id
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "app_insights_app_id" {
  description = "Application Insights App ID"
  value       = azurerm_application_insights.main.app_id
}
