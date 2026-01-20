# Get current client config once at root level (values are static after read)
data "azurerm_client_config" "current" {}

locals {
  base_tags = merge(
    {
      "managed-by" = "terraform"
      "platform"   = var.name
    },
    var.tags
  )
}

# Validation: Container Apps requires Observability
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability (enable_observability = true)' && exit 1"
  }
}

# Foundation: Naming Convention
module "naming" {
  source   = "./modules/foundation/naming"
  name     = var.name
  location = var.location
}

# Foundation: Resource Group (always created)
module "resource_group" {
  source   = "./modules/foundation/resource-group"
  name     = module.naming.resource_group
  location = var.location
  tags     = local.base_tags
}

# Security: Managed Identity (optional - required by Storage, Service Bus, Event Grid, SQL, Key Vault)
module "managed_identity" {
  count               = var.enable_managed_identity ? 1 : 0
  source              = "./modules/security/managed-identity"
  name                = module.naming.managed_identity
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.base_tags
}

# Networking: VNet Spoke (optional)
module "vnet_spoke" {
  count                      = var.enable_vnet ? 1 : 0
  source                     = "./modules/networking/vnet-spoke"
  name                       = module.naming.vnet
  location                   = var.location
  resource_group_name        = module.resource_group.name
  container_apps_subnet_name = module.naming.subnet_container_apps
  tags                       = local.base_tags
}

# Workloads: Observability (optional)
module "observability" {
  count               = var.enable_observability ? 1 : 0
  source              = "./modules/workloads/observability"
  name                = var.name
  location            = var.location
  resource_group_name = module.resource_group.name
  naming              = module.naming
  tags                = local.base_tags
}

# Workloads: Storage Account (optional) - uses Managed Identity for RBAC if enabled
module "storage_account" {
  count                      = var.enable_storage ? 1 : 0
  source                     = "./modules/workloads/storage-account"
  name                       = module.naming.storage_account
  location                   = var.location
  resource_group_name        = module.resource_group.name
  managed_identity_id        = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  vnet_subnet_ids            = var.enable_vnet ? [module.vnet_spoke[0].default_subnet_id] : []
  tags                       = local.base_tags
  enable_observability       = var.enable_observability
  log_analytics_workspace_id = var.enable_observability ? module.observability[0].log_analytics_id : null
}

# Workloads: Service Bus (optional) - uses Managed Identity for RBAC if enabled
module "service_bus" {
  count                      = var.enable_service_bus ? 1 : 0
  source                     = "./modules/workloads/service-bus"
  name                       = module.naming.service_bus
  location                   = var.location
  resource_group_name        = module.resource_group.name
  managed_identity_id        = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  tags                       = local.base_tags
  enable_observability       = var.enable_observability
  log_analytics_workspace_id = var.enable_observability ? module.observability[0].log_analytics_id : null
}

# Workloads: Event Grid (optional) - uses Managed Identity for RBAC if enabled
module "event_grid" {
  count                          = var.enable_event_grid ? 1 : 0
  source                         = "./modules/workloads/event-grid"
  name                           = module.naming.event_grid_domain
  location                       = var.location
  resource_group_name            = module.resource_group.name
  managed_identity_id            = var.enable_managed_identity ? module.managed_identity[0].id : null
  service_bus_topic_id           = var.enable_service_bus ? module.service_bus[0].topic_id : null
  enable_service_bus_integration = var.enable_service_bus
  tags                           = local.base_tags
  enable_observability           = var.enable_observability
  log_analytics_workspace_id     = var.enable_observability ? module.observability[0].log_analytics_id : null
}

# Workloads: SQL Server & Database (optional) - uses Managed Identity for RBAC if enabled
module "sql" {
  count                      = var.enable_sql ? 1 : 0
  source                     = "./modules/workloads/sql"
  server_name                = module.naming.sql_server
  database_name              = module.naming.sql_database
  location                   = var.location
  resource_group_name        = module.resource_group.name
  managed_identity_id        = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  vnet_subnet_ids            = var.enable_vnet ? [module.vnet_spoke[0].default_subnet_id] : []
  tags                       = local.base_tags
  enable_observability       = var.enable_observability
  log_analytics_workspace_id = var.enable_observability ? module.observability[0].log_analytics_id : null
}

# Security: Key Vault (optional) - depends on SQL for password storage, uses Managed Identity for RBAC if enabled
module "key_vault" {
  count                = var.enable_key_vault ? 1 : 0
  source               = "./modules/security/key-vault"
  name                 = module.naming.key_vault
  location             = var.location
  resource_group_name  = module.resource_group.name
  tenant_id            = data.azurerm_client_config.current.tenant_id
  current_principal_id = data.azurerm_client_config.current.object_id
  managed_identity_id  = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  secrets = var.enable_sql ? {
    "sql-admin-password" = module.sql[0].admin_password
  } : {}
  tags                       = local.base_tags
  enable_observability       = var.enable_observability
  log_analytics_workspace_id = var.enable_observability ? module.observability[0].log_analytics_id : null

  depends_on = [module.sql]
}

# Workloads: Container Apps Environment (optional) - requires Observability
module "container_apps" {
  count                      = var.enable_container_apps && var.enable_observability ? 1 : 0
  source                     = "./modules/workloads/container-apps"
  name                       = module.naming.container_apps_environment
  location                   = var.location
  resource_group_name        = module.resource_group.name
  log_analytics_workspace_id = module.observability[0].log_analytics_id
  infrastructure_subnet_id   = var.enable_vnet ? module.vnet_spoke[0].container_apps_subnet_id : null
  tags                       = local.base_tags
}

# RBAC: SQL access to Key Vault (if SQL, Key Vault and Managed Identity are enabled)
resource "azurerm_role_assignment" "sql_key_vault_access" {
  count                = var.enable_sql && var.enable_key_vault && var.enable_managed_identity ? 1 : 0
  name                 = uuidv5("dns", "${module.key_vault[0].id}-${module.sql[0].identity_principal_id}-secrets-officer")
  scope                = module.key_vault[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = module.sql[0].identity_principal_id

  depends_on = [module.sql, module.key_vault]
}
