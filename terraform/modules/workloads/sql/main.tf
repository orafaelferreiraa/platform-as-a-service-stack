# Workload Module: SQL Server & Database
# Creates Azure SQL Server and Database with automatic password generation

# Generate random password for SQL admin
resource "random_password" "sql_admin" {
  length           = 16
  override_special = "!@#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

data "azurerm_client_config" "current" {}

resource "azurerm_mssql_server" "main" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.sql_version

  # Default admin user (sql_admin) with auto-generated password
  administrator_login          = var.administrator_login != null ? var.administrator_login : "sql_admin"
  administrator_login_password = random_password.sql_admin.result

  # Security settings
  minimum_tls_version           = "1.2"
  public_network_access_enabled = var.public_network_access_enabled

  # Identity for managed identity support
  identity {
    type         = var.managed_identity_id != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.managed_identity_id != null ? [var.managed_identity_id] : []
  }

  # Optional Azure AD Administrator
  dynamic "azuread_administrator" {
    for_each = var.azuread_admin_login != null && var.azuread_admin_object_id != null ? [1] : []
    content {
      login_username              = var.azuread_admin_login
      object_id                   = var.azuread_admin_object_id
      tenant_id                   = data.azurerm_client_config.current.tenant_id
      azuread_authentication_only = var.azuread_authentication_only
    }
  }

  tags = var.tags
}

# Database
resource "azurerm_mssql_database" "main" {
  name      = var.database_name
  server_id = azurerm_mssql_server.main.id

  collation      = var.collation
  max_size_gb    = var.max_size_gb
  sku_name       = var.sku_name
  zone_redundant = var.zone_redundant

  # Backup settings
  geo_backup_enabled = var.geo_backup_enabled

  dynamic "short_term_retention_policy" {
    for_each = var.short_term_retention_days != null ? [1] : []
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

  tags = var.tags
}

# Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count = var.allow_azure_services ? 1 : 0

  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# VNet rule for subnet access
resource "azurerm_mssql_virtual_network_rule" "vnet" {
  count = var.subnet_id != null ? 1 : 0

  name      = "vnet-rule"
  server_id = azurerm_mssql_server.main.id
  subnet_id = var.subnet_id
}
