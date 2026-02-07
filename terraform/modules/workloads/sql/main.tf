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
#checkov:skip=CKV_AZURE_24:Audit retention managed by Log Analytics workspace retention policy - retention_in_days deprecated in azurerm 4.x
#checkov:skip=CKV2_AZURE_27:Azure AD-only auth requires org-specific AD configuration - SQL auth maintained for platform flexibility
#tfsec:ignore:azure-database-no-public-access Public access required for GitHub-hosted CI/CD runners and Azure PaaS service connectivity
resource "azurerm_mssql_server" "main" {
  name                          = var.server_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = "12.0"
  administrator_login           = var.administrator_login
  administrator_login_password  = random_password.sql_admin.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true # Required for GitHub-hosted CI/CD runners and Azure PaaS services

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Firewall rule to allow Azure services
#checkov:skip=CKV_AZURE_132:AllowAzureServices required for platform connectivity from GitHub-hosted CI/CD
#checkov:skip=CKV2_AZURE_34:AllowAzureServices (0.0.0.0) required for Azure PaaS services and GitHub-hosted runners connectivity
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

  lifecycle {
    ignore_changes = [geo_backup_enabled]
  }
}

# SQL Server Extended Auditing Policy
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id              = azurerm_mssql_server.main.id
  log_monitoring_enabled = true
}

# SQL Server Security Alert Policy
#tfsec:ignore:azure-database-threat-alert-email-set Alert email addresses are org-specific - configured post-deployment by platform consumers
resource "azurerm_mssql_server_security_alert_policy" "main" {
  resource_group_name  = var.resource_group_name
  server_name          = azurerm_mssql_server.main.name
  state                = "Enabled"
  email_account_admins = true
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

  lifecycle {
    ignore_changes = [enabled_metric]
  }
}
