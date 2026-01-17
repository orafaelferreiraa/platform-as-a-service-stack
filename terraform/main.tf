# =============================================================================
# Platform as a Service Stack - Main Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# Foundation: Naming Convention
# -----------------------------------------------------------------------------
module "naming" {
  source = "./modules/foundation/naming"

  name     = var.name
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# Foundation: Resource Group
# -----------------------------------------------------------------------------
module "resource_group" {
  source = "./modules/foundation/resource-group"

  name     = module.naming.resource_group
  location = var.location
  tags     = module.naming.default_tags
}

# -----------------------------------------------------------------------------
# Security: Managed Identity
# Base for all RBAC-enabled resources
# -----------------------------------------------------------------------------
module "managed_identity" {
  source = "./modules/security/managed-identity"

  name                = module.naming.managed_identity
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = module.naming.default_tags
}

# -----------------------------------------------------------------------------
# Networking: VNet Spoke (Optional)
# -----------------------------------------------------------------------------
module "vnet" {
  source = "./modules/networking/vnet-spoke"
  count  = var.enable_vnet ? 1 : 0

  name                = module.naming.vnet
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = var.vnet_address_space
  subnets             = var.vnet_subnets
  tags                = module.naming.default_tags
}

# -----------------------------------------------------------------------------
# Workload: Observability (Log Analytics + App Insights)
# Required for Container Apps and diagnostics
# -----------------------------------------------------------------------------
module "observability" {
  source = "./modules/workloads/observability"
  count  = var.enable_observability ? 1 : 0

  log_analytics_name  = module.naming.log_analytics
  app_insights_name   = module.naming.app_insights
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = module.naming.default_tags
}

# -----------------------------------------------------------------------------
# Security: Key Vault
# Stores secrets like SQL password
# -----------------------------------------------------------------------------
module "key_vault" {
  source = "./modules/security/key-vault"
  count  = var.enable_key_vault ? 1 : 0

  name                          = module.naming.key_vault
  resource_group_name           = module.resource_group.name
  location                      = var.location
  managed_identity_principal_id = module.managed_identity.principal_id

  # Store SQL admin password if SQL is enabled
  secrets = var.enable_sql ? {
    "sql-admin-password" = module.sql[0].admin_password
  } : {}

  tags = module.naming.default_tags

  depends_on = [module.sql]
}

# -----------------------------------------------------------------------------
# Workload: Storage Account
# -----------------------------------------------------------------------------
module "storage" {
  source = "./modules/workloads/storage-account"
  count  = var.enable_storage ? 1 : 0

  name                          = module.naming.storage_account
  resource_group_name           = module.resource_group.name
  location                      = var.location
  managed_identity_id           = module.managed_identity.id
  managed_identity_principal_id = module.managed_identity.principal_id

  network_rules = var.enable_vnet ? {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [module.vnet[0].subnet_default_id]
  } : null

  tags = module.naming.default_tags
}

# Diagnostic Settings for Storage
resource "azurerm_monitor_diagnostic_setting" "storage" {
  count = var.enable_storage && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.storage_account}"
  target_resource_id         = "${module.storage[0].id}/blobServices/default"
  log_analytics_workspace_id = module.observability[0].log_analytics_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# -----------------------------------------------------------------------------
# Workload: Service Bus
# -----------------------------------------------------------------------------
module "service_bus" {
  source = "./modules/workloads/service-bus"
  count  = var.enable_service_bus ? 1 : 0

  name                          = module.naming.service_bus
  resource_group_name           = module.resource_group.name
  location                      = var.location
  sku                           = var.service_bus_sku
  managed_identity_id           = module.managed_identity.id
  managed_identity_principal_id = module.managed_identity.principal_id
  queues                        = var.service_bus_queues
  topics                        = var.service_bus_topics
  tags                          = module.naming.default_tags
}

# Diagnostic Settings for Service Bus
resource "azurerm_monitor_diagnostic_setting" "service_bus" {
  count = var.enable_service_bus && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.service_bus}"
  target_resource_id         = module.service_bus[0].id
  log_analytics_workspace_id = module.observability[0].log_analytics_id

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# -----------------------------------------------------------------------------
# Workload: Event Grid
# -----------------------------------------------------------------------------
module "event_grid" {
  source = "./modules/workloads/event-grid"
  count  = var.enable_event_grid ? 1 : 0

  name                          = module.naming.event_grid_topic
  resource_group_name           = module.resource_group.name
  location                      = var.location
  managed_identity_id           = module.managed_identity.id
  managed_identity_principal_id = module.managed_identity.principal_id
  tags                          = module.naming.default_tags
}

# Diagnostic Settings for Event Grid
resource "azurerm_monitor_diagnostic_setting" "event_grid" {
  count = var.enable_event_grid && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.event_grid_topic}"
  target_resource_id         = module.event_grid[0].id
  log_analytics_workspace_id = module.observability[0].log_analytics_id

  enabled_log {
    category = "DeliveryFailures"
  }

  enabled_log {
    category = "PublishFailures"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# -----------------------------------------------------------------------------
# Workload: SQL Server & Database
# Password is auto-generated and stored in Key Vault
# -----------------------------------------------------------------------------
module "sql" {
  source = "./modules/workloads/sql"
  count  = var.enable_sql ? 1 : 0

  server_name         = module.naming.sql_server
  database_name       = module.naming.sql_database
  resource_group_name = module.resource_group.name
  location            = var.location
  sku_name            = var.sql_sku
  max_size_gb         = var.sql_max_size_gb
  managed_identity_id = module.managed_identity.id
  subnet_id           = var.enable_vnet ? module.vnet[0].subnet_sql_id : null
  tags                = module.naming.default_tags
}

# RBAC: SQL Server identity access to Key Vault (avoids cyclic dependency)
resource "azurerm_role_assignment" "sql_key_vault_access" {
  count = var.enable_sql && var.enable_key_vault ? 1 : 0

  scope                = module.key_vault[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.sql[0].identity_principal_id

  depends_on = [module.sql, module.key_vault]
}

# Diagnostic Settings for SQL Database
resource "azurerm_monitor_diagnostic_setting" "sql" {
  count = var.enable_sql && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.sql_database}"
  target_resource_id         = module.sql[0].database_id
  log_analytics_workspace_id = module.observability[0].log_analytics_id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_log {
    category = "AutomaticTuning"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# -----------------------------------------------------------------------------
# Workload: Redis Cache
# -----------------------------------------------------------------------------
module "redis" {
  source = "./modules/workloads/redis-cache"
  count  = var.enable_redis ? 1 : 0

  name                = module.naming.redis_cache
  resource_group_name = module.resource_group.name
  location            = var.location
  sku_name            = var.redis_sku
  capacity            = var.redis_capacity
  family              = var.redis_family
  managed_identity_id = module.managed_identity.id
  subnet_id           = var.enable_vnet && var.redis_sku == "Premium" ? module.vnet[0].subnet_redis_id : null
  tags                = module.naming.default_tags
}

# Diagnostic Settings for Redis
resource "azurerm_monitor_diagnostic_setting" "redis" {
  count = var.enable_redis && var.enable_observability ? 1 : 0

  name                       = "diag-${module.naming.redis_cache}"
  target_resource_id         = module.redis[0].id
  log_analytics_workspace_id = module.observability[0].log_analytics_id

  enabled_metric {
    category = "AllMetrics"
  }
}

# -----------------------------------------------------------------------------
# Workload: Container Apps
# Requires Observability
# -----------------------------------------------------------------------------
module "container_apps" {
  source = "./modules/workloads/container-apps"
  count  = var.enable_container_apps && var.enable_observability ? 1 : 0

  environment_name           = module.naming.container_apps_env
  resource_group_name        = module.resource_group.name
  location                   = var.location
  log_analytics_workspace_id = module.observability[0].log_analytics_id
  managed_identity_id        = module.managed_identity.id
  subnet_id                  = var.enable_vnet ? module.vnet[0].subnet_container_apps_id : null
  container_apps             = var.container_apps
  tags                       = module.naming.default_tags

  depends_on = [module.observability]
}
