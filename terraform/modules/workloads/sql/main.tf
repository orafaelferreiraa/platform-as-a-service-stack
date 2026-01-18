data "azurerm_client_config" "current" {}

# Generate random password for SQL admin
resource "random_password" "sql_admin" {
  length           = 16
  override_special = "!@#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# SQL Server with system-assigned identity
resource "azurerm_mssql_server" "main" {
  name                         = var.server_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  version                      = "12.0"
  administrator_login          = var.administrator_login
  administrator_login_password = random_password.sql_admin.result
  minimum_tls_version          = "1.2"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Virtual network rules (if VNet is enabled)
resource "azurerm_mssql_virtual_network_rule" "main" {
  count     = length(var.vnet_subnet_ids)
  name      = "vnet-rule-${count.index}"
  server_id = azurerm_mssql_server.main.id
  subnet_id = var.vnet_subnet_ids[count.index]
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name                                = var.database_name
  server_id                           = azurerm_mssql_server.main.id
  collation                           = "SQL_Latin1_General_CP1_CI_AS"
  sku_name                            = "Basic"
  max_size_gb                         = 2
  read_scale                          = false
  geo_backup_enabled                  = false
  storage_account_type                = "Local"
  transparent_data_encryption_enabled = true

  tags = var.tags
}

# Note: SQL Server-level diagnostic settings are not supported.
# SQLSecurityAuditEvents and DevOpsOperationsAudit require SQL Database auditing to be enabled.
# Metrics and logs are captured at the database level instead.

# Diagnostic settings for SQL Database
resource "azurerm_monitor_diagnostic_setting" "database" {
  count                      = var.enable_observability ? 1 : 0
  name                       = "diag-${var.database_name}"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_log {
    category = "AutomaticTuning"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "QueryStoreWaitStatistics"
  }

  enabled_log {
    category = "Errors"
  }

  enabled_log {
    category = "DatabaseWaitStatistics"
  }

  enabled_log {
    category = "Timeouts"
  }

  enabled_log {
    category = "Blocks"
  }

  enabled_log {
    category = "Deadlocks"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
