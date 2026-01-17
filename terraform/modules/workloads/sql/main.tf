# =============================================================================
# SQL Module - Azure SQL Server + Database
# Password auto-generated with random_password, user defaults to "sql_admin"
# =============================================================================

resource "random_password" "admin_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_mssql_server" "main" {
  name                          = var.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.sql_version
  administrator_login           = var.administrator_login
  administrator_login_password  = random_password.admin_password.result
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? [var.azuread_administrator] : []
    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      tenant_id                   = azuread_administrator.value.tenant_id
      azuread_authentication_only = azuread_administrator.value.azuread_authentication_only
    }
  }
}

resource "azurerm_mssql_database" "main" {
  name                        = var.database_name
  server_id                   = azurerm_mssql_server.main.id
  collation                   = var.collation
  max_size_gb                 = var.max_size_gb
  sku_name                    = var.sku_name
  zone_redundant              = var.zone_redundant
  auto_pause_delay_in_minutes = var.sku_name == "GP_S_Gen5_1" ? var.auto_pause_delay_in_minutes : null
  min_capacity                = var.sku_name == "GP_S_Gen5_1" ? var.min_capacity : null
  read_replica_count          = var.read_replica_count
  read_scale                  = var.read_scale
  tags                        = var.tags

  dynamic "short_term_retention_policy" {
    for_each = var.short_term_retention_days > 0 ? [1] : []
    content {
      retention_days = var.short_term_retention_days
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = var.long_term_retention != null ? [var.long_term_retention] : []
    content {
      weekly_retention  = long_term_retention_policy.value.weekly_retention
      monthly_retention = long_term_retention_policy.value.monthly_retention
      yearly_retention  = long_term_retention_policy.value.yearly_retention
      week_of_year      = long_term_retention_policy.value.week_of_year
    }
  }
}

resource "azurerm_mssql_firewall_rule" "azure_services" {
  count = var.allow_azure_services ? 1 : 0

  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "custom" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name             = each.value.name
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_mssql_virtual_network_rule" "vnet_rules" {
  for_each = { for rule in var.vnet_rules : rule.name => rule }

  name      = each.value.name
  server_id = azurerm_mssql_server.main.id
  subnet_id = each.value.subnet_id
}
