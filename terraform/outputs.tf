# =============================================================================
# Platform as a Service Stack - Outputs
# =============================================================================

# =============================================================================
# Foundation Outputs
# =============================================================================

output "resource_group_id" {
  value = module.resource_group.id
}

output "resource_group_name" {
  value = module.resource_group.name
}

output "resource_group_location" {
  value = module.resource_group.location
}

# =============================================================================
# Security Outputs
# =============================================================================

output "managed_identity_id" {
  value = module.managed_identity.id
}

output "managed_identity_principal_id" {
  value = module.managed_identity.principal_id
}

output "managed_identity_client_id" {
  value = module.managed_identity.client_id
}

output "key_vault_id" {
  value = var.enable_key_vault ? module.key_vault[0].id : null
}

output "key_vault_name" {
  value = var.enable_key_vault ? module.key_vault[0].name : null
}

output "key_vault_uri" {
  value = var.enable_key_vault ? module.key_vault[0].vault_uri : null
}

# =============================================================================
# Networking Outputs
# =============================================================================

output "vnet_id" {
  value = var.enable_vnet ? module.vnet[0].id : null
}

output "vnet_name" {
  value = var.enable_vnet ? module.vnet[0].name : null
}

output "default_subnet_id" {
  value = var.enable_vnet ? module.vnet[0].default_subnet_id : null
}

output "container_apps_subnet_id" {
  value = var.enable_vnet && var.enable_container_apps ? module.vnet[0].container_apps_subnet_id : null
}

output "private_endpoints_subnet_id" {
  value = var.enable_vnet ? module.vnet[0].private_endpoints_subnet_id : null
}

# =============================================================================
# Observability Outputs
# =============================================================================

output "log_analytics_workspace_id" {
  value = var.enable_observability ? module.observability[0].log_analytics_workspace_id : null
}

output "log_analytics_workspace_name" {
  value = var.enable_observability ? module.observability[0].log_analytics_workspace_name : null
}

output "app_insights_id" {
  value = var.enable_observability ? module.observability[0].app_insights_id : null
}

output "app_insights_name" {
  value = var.enable_observability ? module.observability[0].app_insights_name : null
}

output "app_insights_instrumentation_key" {
  value     = var.enable_observability ? module.observability[0].app_insights_instrumentation_key : null
  sensitive = true
}

output "app_insights_connection_string" {
  value     = var.enable_observability ? module.observability[0].app_insights_connection_string : null
  sensitive = true
}

# =============================================================================
# Storage Outputs
# =============================================================================

output "storage_account_id" {
  value = var.enable_storage ? module.storage_account[0].id : null
}

output "storage_account_name" {
  value = var.enable_storage ? module.storage_account[0].name : null
}

output "storage_account_primary_blob_endpoint" {
  value = var.enable_storage ? module.storage_account[0].primary_blob_endpoint : null
}

# =============================================================================
# Service Bus Outputs
# =============================================================================

output "service_bus_id" {
  value = var.enable_service_bus ? module.service_bus[0].id : null
}

output "service_bus_name" {
  value = var.enable_service_bus ? module.service_bus[0].name : null
}

output "service_bus_endpoint" {
  value = var.enable_service_bus ? module.service_bus[0].endpoint : null
}

output "service_bus_queue_ids" {
  value = var.enable_service_bus ? module.service_bus[0].queue_ids : null
}

output "service_bus_topic_ids" {
  value = var.enable_service_bus ? module.service_bus[0].topic_ids : null
}

# =============================================================================
# Event Grid Outputs
# =============================================================================

output "event_grid_system_topic_id" {
  value = var.enable_event_grid && var.enable_storage ? module.event_grid[0].system_topic_id : null
}

output "event_grid_system_topic_name" {
  value = var.enable_event_grid && var.enable_storage ? module.event_grid[0].system_topic_name : null
}

# =============================================================================
# SQL Outputs
# =============================================================================

output "sql_server_id" {
  value = var.enable_sql ? module.sql[0].server_id : null
}

output "sql_server_name" {
  value = var.enable_sql ? module.sql[0].server_name : null
}

output "sql_server_fqdn" {
  value = var.enable_sql ? module.sql[0].server_fqdn : null
}

output "sql_database_id" {
  value = var.enable_sql ? module.sql[0].database_id : null
}

output "sql_database_name" {
  value = var.enable_sql ? module.sql[0].database_name : null
}

output "sql_administrator_login" {
  value = var.enable_sql ? module.sql[0].administrator_login : null
}

output "sql_administrator_password" {
  value     = var.enable_sql ? module.sql[0].administrator_password : null
  sensitive = true
}

output "sql_connection_string" {
  value     = var.enable_sql ? module.sql[0].connection_string : null
  sensitive = true
}

# =============================================================================
# Redis Outputs
# =============================================================================

output "redis_id" {
  value = var.enable_redis ? module.redis[0].id : null
}

output "redis_name" {
  value = var.enable_redis ? module.redis[0].name : null
}

output "redis_hostname" {
  value = var.enable_redis ? module.redis[0].hostname : null
}

output "redis_port" {
  value = var.enable_redis ? module.redis[0].port : null
}

output "redis_ssl_port" {
  value = var.enable_redis ? module.redis[0].ssl_port : null
}

output "redis_primary_connection_string" {
  value     = var.enable_redis ? module.redis[0].primary_connection_string : null
  sensitive = true
}

# =============================================================================
# Container Apps Outputs
# =============================================================================

output "container_apps_environment_id" {
  value = var.enable_container_apps ? module.container_apps[0].environment_id : null
}

output "container_apps_environment_name" {
  value = var.enable_container_apps ? module.container_apps[0].environment_name : null
}

output "container_apps_default_domain" {
  value = var.enable_container_apps ? module.container_apps[0].default_domain : null
}

output "container_apps_static_ip" {
  value = var.enable_container_apps ? module.container_apps[0].static_ip_address : null
}

output "container_app_ids" {
  value = var.enable_container_apps ? module.container_apps[0].container_app_ids : null
}

output "container_app_fqdns" {
  value = var.enable_container_apps ? module.container_apps[0].container_app_fqdns : null
}

output "container_app_urls" {
  value = var.enable_container_apps ? module.container_apps[0].container_app_urls : null
}
