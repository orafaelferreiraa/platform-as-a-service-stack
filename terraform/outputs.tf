output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

output "managed_identity_id" {
  description = "ID of the managed identity"
  value       = module.managed_identity.id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = module.managed_identity.principal_id
}

output "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  value       = module.managed_identity.client_id
}

# VNet outputs
output "vnet_id" {
  description = "ID of the VNet"
  value       = var.enable_vnet ? module.vnet_spoke[0].id : null
}

output "vnet_name" {
  description = "Name of the VNet"
  value       = var.enable_vnet ? module.vnet_spoke[0].name : null
}

# Observability outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = var.enable_observability ? module.observability[0].log_analytics_id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.enable_observability ? module.observability[0].app_insights_instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = var.enable_observability ? module.observability[0].app_insights_connection_string : null
  sensitive   = true
}

# Storage Account outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = var.enable_storage ? module.storage_account[0].name : null
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = var.enable_storage ? module.storage_account[0].id : null
}

# Service Bus outputs
output "service_bus_namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = var.enable_service_bus ? module.service_bus[0].namespace_id : null
}

output "service_bus_namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = var.enable_service_bus ? module.service_bus[0].namespace_name : null
}

# Event Grid outputs
output "event_grid_domain_id" {
  description = "ID of the Event Grid domain"
  value       = var.enable_event_grid ? module.event_grid[0].domain_id : null
}

# SQL outputs
output "sql_server_id" {
  description = "ID of the SQL server"
  value       = var.enable_sql ? module.sql[0].server_id : null
}

output "sql_server_fqdn" {
  description = "FQDN of the SQL server"
  value       = var.enable_sql ? module.sql[0].server_fqdn : null
}

output "sql_database_id" {
  description = "ID of the SQL database"
  value       = var.enable_sql ? module.sql[0].database_id : null
}

# Key Vault outputs
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = var.enable_key_vault ? module.key_vault[0].id : null
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.enable_key_vault ? module.key_vault[0].vault_uri : null
}

# Container Apps outputs
output "container_apps_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = var.enable_container_apps && var.enable_observability ? module.container_apps[0].id : null
}

output "container_apps_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = var.enable_container_apps && var.enable_observability ? module.container_apps[0].name : null
}
