# Foundation resources
output "resource_group" {
  description = "Resource group name"
  value       = "rg-${local.base_name_pattern}"
}

output "managed_identity" {
  description = "Managed identity name"
  value       = "id-${local.base_name_pattern}"
}

# Networking
output "vnet" {
  description = "Virtual network name"
  value       = "vnet-${local.base_name_pattern}"
}

output "subnet_default" {
  description = "Default subnet name"
  value       = "snet-default-${local.base_name_pattern}"
}

output "subnet_container_apps" {
  description = "Container Apps subnet name"
  value       = "snet-ca-${local.base_name_pattern}"
}

output "nsg" {
  description = "Network security group name"
  value       = "nsg-${local.base_name_pattern}"
}

# Security
output "key_vault" {
  description = "Key Vault name (globally unique with suffix)"
  value       = "kv${local.base_name_unique_compact}"
}

# Workloads - Storage
output "storage_account" {
  description = "Storage account name (globally unique with suffix)"
  value       = "st${local.base_name_unique_compact}"
}

# Workloads - Messaging
output "service_bus" {
  description = "Service Bus namespace name (globally unique with suffix)"
  value       = "sb-${local.base_name_pattern_unique}"
}

output "service_bus_queue" {
  description = "Service Bus queue name"
  value       = "sbq-events"
}

output "service_bus_topic" {
  description = "Service Bus topic name"
  value       = "sbt-events"
}

output "event_grid_domain" {
  description = "Event Grid domain name"
  value       = "evgd-${local.base_name_pattern}"
}

output "event_grid_topic" {
  description = "Event Grid topic name"
  value       = "evgt-${local.base_name_pattern}"
}

output "event_grid_subscription" {
  description = "Event Grid subscription name"
  value       = "evgs-${local.base_name_pattern}"
}

# Workloads - Data
output "sql_server" {
  description = "SQL Server name (globally unique with suffix)"
  value       = "sql-${local.base_name_pattern_unique}"
}

output "sql_database" {
  description = "SQL Database name"
  value       = "sqldb-${local.base_name_pattern}"
}

# Workloads - Observability
output "log_analytics_workspace" {
  description = "Log Analytics Workspace name"
  value       = "log-${local.base_name_pattern}"
}

output "application_insights" {
  description = "Application Insights name"
  value       = "appi-${local.base_name_pattern}"
}

# Workloads - Containers
output "container_apps_environment" {
  description = "Container Apps Environment name (globally unique with suffix)"
  value       = "cae-${local.base_name_pattern_unique}"
}

# Deterministic suffix for reference
output "suffix" {
  description = "Deterministic suffix used for globally unique names (based on MD5 hash of name)"
  value       = local.suffix
}
