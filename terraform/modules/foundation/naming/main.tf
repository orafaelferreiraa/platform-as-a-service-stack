# =============================================================================
# Naming Module - Convenções de nomenclatura para recursos Azure
# =============================================================================

locals {
  name = lower(replace(var.name, "/[^a-zA-Z0-9-]/", ""))

  location_abbreviations = {
    "eastus"         = "eus"
    "eastus2"        = "eus2"
    "westus"         = "wus"
    "westus2"        = "wus2"
    "westus3"        = "wus3"
    "centralus"      = "cus"
    "northcentralus" = "ncus"
    "southcentralus" = "scus"
    "westeurope"     = "weu"
    "northeurope"    = "neu"
    "brazilsouth"    = "brs"
    "uksouth"        = "uks"
    "ukwest"         = "ukw"
  }

  location_abbr        = lookup(local.location_abbreviations, var.location, substr(var.location, 0, 4))
  base_name            = "${local.name}-${local.location_abbr}"
  base_name_no_hyphen  = "${local.name}${local.location_abbr}"

  names = {
    resource_group          = "rg-${local.base_name}"
    managed_identity        = "id-${local.base_name}"
    key_vault               = "kv-${local.base_name_no_hyphen}"
    storage_account         = "st${local.base_name_no_hyphen}"
    log_analytics_workspace = "log-${local.base_name}"
    application_insights    = "appi-${local.base_name}"
    service_bus_namespace   = "sb-${local.base_name}"
    event_grid_topic        = "evgt-${local.base_name}"
    sql_server              = "sql-${local.base_name}"
    sql_database            = "sqldb-${local.base_name}"
    redis_cache             = "redis-${local.base_name}"
    container_apps_env      = "cae-${local.base_name}"
    virtual_network         = "vnet-${local.base_name}"
    subnet                  = "snet-${local.base_name}"
    nsg                     = "nsg-${local.base_name}"
  }

  default_tags = {
    managed_by = "terraform"
    platform   = var.name
    location   = var.location
  }
}
