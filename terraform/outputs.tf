# =============================================================================
# Platform Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Foundation
# -----------------------------------------------------------------------------
output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = module.resource_group.id
}

output "location" {
  description = "Azure region"
  value       = var.location
}

# -----------------------------------------------------------------------------
# Security: Managed Identity
# -----------------------------------------------------------------------------
output "managed_identity_id" {
  description = "Managed Identity resource ID"
  value       = module.managed_identity.id
}

output "managed_identity_client_id" {
  description = "Managed Identity client ID"
  value       = module.managed_identity.client_id
}

output "managed_identity_principal_id" {
  description = "Managed Identity principal ID"
  value       = module.managed_identity.principal_id
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
output "vnet_id" {
  description = "Virtual Network ID"
  value       = var.enable_vnet ? module.vnet[0].id : null
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = var.enable_vnet ? module.vnet[0].name : null
}

# -----------------------------------------------------------------------------
# Observability
# -----------------------------------------------------------------------------
output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = var.enable_observability ? module.observability[0].log_analytics_id : null
}

output "app_insights_id" {
  description = "Application Insights ID"
  value       = var.enable_observability ? module.observability[0].app_insights_id : null
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = var.enable_observability ? module.observability[0].app_insights_connection_string : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------
output "key_vault_id" {
  description = "Key Vault ID"
  value       = var.enable_key_vault ? module.key_vault[0].id : null
}

output "key_vault_uri" {
  description = "Key Vault URI (use for secret retrieval at runtime)"
  value       = var.enable_key_vault ? module.key_vault[0].vault_uri : null
}

# -----------------------------------------------------------------------------
# Storage Account
# -----------------------------------------------------------------------------
output "storage_account_id" {
  description = "Storage Account ID"
  value       = var.enable_storage ? module.storage[0].id : null
}

output "storage_account_name" {
  description = "Storage Account name"
  value       = var.enable_storage ? module.storage[0].name : null
}

output "storage_primary_blob_endpoint" {
  description = "Storage Account primary blob endpoint"
  value       = var.enable_storage ? module.storage[0].primary_blob_endpoint : null
}

# -----------------------------------------------------------------------------
# Service Bus
# -----------------------------------------------------------------------------
output "service_bus_id" {
  description = "Service Bus namespace ID"
  value       = var.enable_service_bus ? module.service_bus[0].id : null
}

output "service_bus_endpoint" {
  description = "Service Bus namespace endpoint"
  value       = var.enable_service_bus ? module.service_bus[0].endpoint : null
}

# -----------------------------------------------------------------------------
# Event Grid
# -----------------------------------------------------------------------------
output "event_grid_topic_id" {
  description = "Event Grid topic ID"
  value       = var.enable_event_grid ? module.event_grid[0].id : null
}

output "event_grid_topic_endpoint" {
  description = "Event Grid topic endpoint"
  value       = var.enable_event_grid ? module.event_grid[0].endpoint : null
}

# -----------------------------------------------------------------------------
# SQL
# -----------------------------------------------------------------------------
output "sql_server_id" {
  description = "SQL Server ID"
  value       = var.enable_sql ? module.sql[0].server_id : null
}

output "sql_server_fqdn" {
  description = "SQL Server fully qualified domain name"
  value       = var.enable_sql ? module.sql[0].server_fqdn : null
}

output "sql_database_id" {
  description = "SQL Database ID"
  value       = var.enable_sql ? module.sql[0].database_id : null
}

output "sql_connection_string" {
  description = "SQL connection string template (uses Managed Identity auth)"
  value       = var.enable_sql ? module.sql[0].connection_string : null
}

# -----------------------------------------------------------------------------
# Redis
# -----------------------------------------------------------------------------
output "redis_id" {
  description = "Redis Cache ID"
  value       = var.enable_redis ? module.redis[0].id : null
}

output "redis_hostname" {
  description = "Redis Cache hostname"
  value       = var.enable_redis ? module.redis[0].hostname : null
}

output "redis_port" {
  description = "Redis Cache SSL port"
  value       = var.enable_redis ? module.redis[0].port : null
}

# -----------------------------------------------------------------------------
# Container Apps
# -----------------------------------------------------------------------------
output "container_apps_environment_id" {
  description = "Container Apps Environment ID"
  value       = var.enable_container_apps && var.enable_observability ? module.container_apps[0].environment_id : null
}

output "container_apps_default_domain" {
  description = "Container Apps Environment default domain"
  value       = var.enable_container_apps && var.enable_observability ? module.container_apps[0].default_domain : null
}

output "container_apps_fqdns" {
  description = "Map of Container App names to their FQDNs"
  value       = var.enable_container_apps && var.enable_observability ? module.container_apps[0].app_fqdns : null
}
