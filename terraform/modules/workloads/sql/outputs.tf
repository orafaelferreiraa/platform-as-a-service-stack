# =============================================================================
# SQL Module - Outputs
# =============================================================================

output "server_id" {
  value = azurerm_mssql_server.main.id
}

output "server_name" {
  value = azurerm_mssql_server.main.name
}

output "server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_id" {
  value = azurerm_mssql_database.main.id
}

output "database_name" {
  value = azurerm_mssql_database.main.name
}

output "administrator_login" {
  value = azurerm_mssql_server.main.administrator_login
}

output "administrator_password" {
  value     = random_password.admin_password.result
  sensitive = true
}

output "connection_string" {
  value     = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${azurerm_mssql_server.main.administrator_login};Password=${random_password.admin_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive = true
}
