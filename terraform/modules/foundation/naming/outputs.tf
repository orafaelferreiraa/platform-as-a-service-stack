output "name" {
  description = "Normalized name"
  value       = local.name
}

output "location" {
  description = "Azure location"
  value       = var.location
}

output "location_abbr" {
  description = "Abbreviated location code"
  value       = local.location_abbr
}

output "base_name" {
  description = "Base name pattern (name-location_abbr)"
  value       = local.base_name_pattern
}

output "resource_group" {
  description = "Resource group name"
  value       = "rg-${local.base_name_pattern}"
}

output "managed_identity" {
  description = "User assigned managed identity name"
  value       = "id-${local.base_name_pattern}"
}

output "key_vault" {
  description = "Key Vault name (no hyphens, max 24 chars)"
  value       = substr("kv${local.name}${local.location_abbr}", 0, 24)
}

output "storage_account" {
  description = "Storage account name (no hyphens, max 24 chars)"
  value       = substr("st${local.name}${local.location_abbr}", 0, 24)
}

output "log_analytics" {
  description = "Log Analytics workspace name"
  value       = "log-${local.base_name_pattern}"
}

output "app_insights" {
  description = "Application Insights name"
  value       = "appi-${local.base_name_pattern}"
}

output "service_bus" {
  description = "Service Bus namespace name"
  value       = "sb-${local.base_name_pattern}"
}

output "event_grid_topic" {
  description = "Event Grid topic name"
  value       = "evgt-${local.base_name_pattern}"
}

output "sql_server" {
  description = "SQL Server name"
  value       = "sql-${local.base_name_pattern}"
}

output "sql_database" {
  description = "SQL Database name"
  value       = "sqldb-${local.base_name_pattern}"
}

output "redis_cache" {
  description = "Redis Cache name"
  value       = "redis-${local.base_name_pattern}"
}

output "container_apps_env" {
  description = "Container Apps Environment name"
  value       = "cae-${local.base_name_pattern}"
}

output "vnet" {
  description = "Virtual Network name"
  value       = "vnet-${local.base_name_pattern}"
}

output "default_tags" {
  description = "Default tags for all resources"
  value       = local.default_tags
}
