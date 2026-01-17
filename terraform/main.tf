# =============================================================================
# Platform as a Service Stack - Main Configuration
# =============================================================================

locals {
  location = "eastus2"
  tags = {
    Project     = var.name
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

# =============================================================================
# Foundation - Naming Convention
# =============================================================================

module "naming" {
  source = "./modules/foundation/naming"

  name     = var.name
  location = local.location
}

# =============================================================================
# Foundation - Resource Group
# =============================================================================

module "resource_group" {
  source = "./modules/foundation/resource-group"

  name     = module.naming.names.resource_group
  location = local.location
  tags     = local.tags
}

# =============================================================================
# Security - Managed Identity
# =============================================================================

module "managed_identity" {
  source = "./modules/security/managed-identity"

  name                = module.naming.names.managed_identity
  resource_group_name = module.resource_group.name
  location            = local.location
  tags                = local.tags
}

# =============================================================================
# Networking - VNet Spoke (Optional)
# =============================================================================

module "vnet" {
  source = "./modules/networking/vnet-spoke"
  count  = var.enable_vnet ? 1 : 0

  name                            = module.naming.names.vnet
  resource_group_name             = module.resource_group.name
  location                        = local.location
  address_space                   = var.vnet_config.address_space
  subnets                         = var.vnet_config.subnets
  enable_container_apps_subnet    = var.enable_container_apps
  enable_private_endpoints_subnet = var.vnet_config.enable_private_endpoints
  nsg_name                        = module.naming.names.nsg
  tags                            = local.tags
}

# =============================================================================
# Workloads - Observability (Optional)
# =============================================================================

module "observability" {
  source = "./modules/workloads/observability"
  count  = var.enable_observability ? 1 : 0

  log_analytics_name  = module.naming.names.log_analytics
  app_insights_name   = module.naming.names.app_insights
  resource_group_name = module.resource_group.name
  location            = local.location
  retention_in_days   = var.observability_config.retention_in_days
  tags                = local.tags
}

# =============================================================================
# Security - Key Vault (Optional)
# =============================================================================

module "key_vault" {
  source = "./modules/security/key-vault"
  count  = var.enable_key_vault ? 1 : 0

  name                          = module.naming.names.key_vault
  resource_group_name           = module.resource_group.name
  location                      = local.location
  sku_name                      = var.key_vault_config.sku_name
  purge_protection_enabled      = var.key_vault_config.purge_protection_enabled
  soft_delete_retention_days    = var.key_vault_config.soft_delete_retention_days
  secrets_user_principal_ids    = { "managed-identity" = module.managed_identity.principal_id }
  secrets_officer_principal_ids = { for idx, id in var.key_vault_config.secrets_officer_object_ids : "officer-${idx}" => id }
  secrets                       = var.key_vault_config.secrets
  tags                          = local.tags
}

# =============================================================================
# Workloads - Storage Account (Optional)
# =============================================================================

module "storage_account" {
  source = "./modules/workloads/storage-account"
  count  = var.enable_storage ? 1 : 0

  name                     = module.naming.names.storage_account
  resource_group_name      = module.resource_group.name
  location                 = local.location
  account_tier             = var.storage_config.account_tier
  account_replication_type = var.storage_config.account_replication_type
  containers               = var.storage_config.containers
  identity_principal_id    = module.managed_identity.principal_id
  tags                     = local.tags
}

# =============================================================================
# Workloads - Service Bus (Optional)
# =============================================================================

module "service_bus" {
  source = "./modules/workloads/service-bus"
  count  = var.enable_service_bus ? 1 : 0

  name                  = module.naming.names.service_bus
  resource_group_name   = module.resource_group.name
  location              = local.location
  sku                   = var.service_bus_config.sku
  queues                = var.service_bus_config.queues
  topics                = var.service_bus_config.topics
  subscriptions         = var.service_bus_config.subscriptions
  identity_principal_id = module.managed_identity.principal_id
  tags                  = local.tags
}

# =============================================================================
# Workloads - Event Grid (Optional)
# =============================================================================

module "event_grid" {
  source = "./modules/workloads/event-grid"
  count  = var.enable_event_grid && var.enable_storage ? 1 : 0

  name                   = module.naming.names.event_grid
  resource_group_name    = module.resource_group.name
  location               = local.location
  source_arm_resource_id = module.storage_account[0].id
  topic_type             = "Microsoft.Storage.StorageAccounts"
  subscriptions          = var.event_grid_config.subscriptions
  tags                   = local.tags
}

# =============================================================================
# Workloads - SQL Database (Optional)
# =============================================================================

module "sql" {
  source = "./modules/workloads/sql"
  count  = var.enable_sql ? 1 : 0

  server_name               = module.naming.names.sql_server
  database_name             = module.naming.names.sql_database
  resource_group_name       = module.resource_group.name
  location                  = local.location
  administrator_login       = var.sql_config.administrator_login
  sku_name                  = var.sql_config.sku_name
  max_size_gb               = var.sql_config.max_size_gb
  short_term_retention_days = var.sql_config.backup_retention_days
  allow_azure_services      = true
  tags                      = local.tags
}

# =============================================================================
# Workloads - Redis Cache (Optional)
# =============================================================================

module "redis" {
  source = "./modules/workloads/redis-cache"
  count  = var.enable_redis ? 1 : 0

  name                  = module.naming.names.redis
  resource_group_name   = module.resource_group.name
  location              = local.location
  capacity              = var.redis_config.capacity
  family                = var.redis_config.family
  sku_name              = var.redis_config.sku_name
  identity_principal_id = module.managed_identity.principal_id
  tags                  = local.tags
}

# =============================================================================
# Workloads - Container Apps (Optional)
# =============================================================================

module "container_apps" {
  source = "./modules/workloads/container-apps"
  count  = var.enable_container_apps ? 1 : 0

  environment_name           = module.naming.names.container_apps_environment
  resource_group_name        = module.resource_group.name
  location                   = local.location
  log_analytics_workspace_id = var.enable_observability ? module.observability[0].log_analytics_workspace_id : null
  infrastructure_subnet_id   = var.enable_vnet ? module.vnet[0].container_apps_subnet_id : null
  container_apps             = var.container_apps_config.apps
  tags                       = local.tags
}

# =============================================================================
# Diagnostic Settings
# Uses enabled_metric (not deprecated "metric")
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count = var.enable_key_vault && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.names.key_vault}"
  target_resource_id         = module.key_vault[0].id
  log_analytics_workspace_id = module.observability[0].log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  count = var.enable_storage && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.names.storage_account}"
  target_resource_id         = module.storage_account[0].id
  log_analytics_workspace_id = module.observability[0].log_analytics_workspace_id

  enabled_metric {
    category = "Transaction"
  }
}

resource "azurerm_monitor_diagnostic_setting" "service_bus" {
  count = var.enable_service_bus && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.names.service_bus}"
  target_resource_id         = module.service_bus[0].id
  log_analytics_workspace_id = module.observability[0].log_analytics_workspace_id

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql" {
  count = var.enable_sql && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.names.sql_database}"
  target_resource_id         = module.sql[0].database_id
  log_analytics_workspace_id = module.observability[0].log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  enabled_metric {
    category = "Basic"
  }
}

resource "azurerm_monitor_diagnostic_setting" "redis" {
  count = var.enable_redis && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.names.redis}"
  target_resource_id         = module.redis[0].id
  log_analytics_workspace_id = module.observability[0].log_analytics_workspace_id

  enabled_metric {
    category = "AllMetrics"
  }
}
