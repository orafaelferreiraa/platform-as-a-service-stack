# =============================================================================
# Naming Module - Outputs
# =============================================================================

output "names" {
  description = "Map com todos os nomes de recursos gerados"
  value       = local.names
}

output "resource_group" {
  value = local.names.resource_group
}

output "managed_identity" {
  value = local.names.managed_identity
}

output "key_vault" {
  value = local.names.key_vault
}

output "storage_account" {
  value = local.names.storage_account
}

output "log_analytics_workspace" {
  value = local.names.log_analytics_workspace
}

output "application_insights" {
  value = local.names.application_insights
}

output "service_bus_namespace" {
  value = local.names.service_bus_namespace
}

output "event_grid_topic" {
  value = local.names.event_grid_topic
}

output "sql_server" {
  value = local.names.sql_server
}

output "sql_database" {
  value = local.names.sql_database
}

output "redis_cache" {
  value = local.names.redis_cache
}

output "container_apps_env" {
  value = local.names.container_apps_env
}

output "virtual_network" {
  value = local.names.virtual_network
}

output "subnet" {
  value = local.names.subnet
}

output "nsg" {
  value = local.names.nsg
}

output "default_tags" {
  value = local.default_tags
}

output "base_name" {
  value = local.base_name
}

output "location_abbr" {
  value = local.location_abbr
}
