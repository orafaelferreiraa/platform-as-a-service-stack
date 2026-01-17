output "server_id" {
  description = "SQL Server resource ID"
  value       = azurerm_mssql_server.main.id
}

output "server_name" {
  description = "SQL Server name"
  value       = azurerm_mssql_server.main.name
}

output "server_fqdn" {
  description = "SQL Server fully qualified domain name"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_id" {
  description = "SQL Database resource ID"
  value       = azurerm_mssql_database.main.id
}

output "database_name" {
  description = "SQL Database name"
  value       = azurerm_mssql_database.main.name
}

output "identity_principal_id" {
  description = "System assigned identity principal ID"
  value       = azurerm_mssql_server.main.identity[0].principal_id
}

output "administrator_login" {
  description = "Administrator login username"
  value       = azurerm_mssql_server.main.administrator_login
}

output "admin_password" {
  description = "Administrator password (to be stored in Key Vault)"
  value       = random_password.sql_admin.result
  sensitive   = true
}

output "connection_string" {
  description = "Connection string template (without password)"
  value       = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=Active Directory Default"
}
