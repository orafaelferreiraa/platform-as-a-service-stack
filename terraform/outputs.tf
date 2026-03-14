output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
}

output "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  value       = var.enable_managed_identity ? module.managed_identity[0].client_id : null
}

# VNet outputs
output "vnet_name" {
  description = "Name of the VNet"
  value       = var.enable_vnet ? module.vnet_spoke[0].name : null
}

# Storage Account outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = var.enable_storage ? module.storage_account[0].name : null
}

# Service Bus outputs
output "service_bus_namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = var.enable_service_bus ? module.service_bus[0].namespace_name : null
}

# SQL outputs
output "sql_server_fqdn" {
  description = "FQDN of the SQL server"
  value       = var.enable_sql ? module.sql[0].server_fqdn : null
}

# Key Vault outputs
output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.enable_key_vault ? module.key_vault[0].vault_uri : null
}

# Container Apps outputs
output "container_apps_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = var.enable_container_apps && var.enable_observability ? module.container_apps[0].name : null
}

output "container_apps_environment_default_domain" {
  description = "Default domain of the Container Apps Environment"
  value       = var.enable_container_apps && var.enable_observability ? module.container_apps[0].default_domain : null
}

output "container_apps_environment_static_ip" {
  description = "Static IP address of the Container Apps Environment"
  value       = var.enable_container_apps && var.enable_observability ? module.container_apps[0].static_ip_address : null
}

# Container Registry outputs
output "container_registry_name" {
  description = "Name of the Container Registry"
  value       = var.enable_container_registry ? module.container_registry[0].name : null
}

output "container_registry_login_server" {
  description = "Login server URL of the Container Registry"
  value       = var.enable_container_registry ? module.container_registry[0].login_server : null
}