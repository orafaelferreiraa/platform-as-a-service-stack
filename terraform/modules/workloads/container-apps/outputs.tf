# =============================================================================
# Container Apps Module - Outputs
# =============================================================================

output "environment_id" {
  value = azurerm_container_app_environment.main.id
}

output "environment_name" {
  value = azurerm_container_app_environment.main.name
}

output "default_domain" {
  value = azurerm_container_app_environment.main.default_domain
}

output "static_ip_address" {
  value = azurerm_container_app_environment.main.static_ip_address
}

output "container_app_ids" {
  value = { for k, v in azurerm_container_app.apps : k => v.id }
}

output "container_app_fqdns" {
  value = { for k, v in azurerm_container_app.apps : k => try(v.ingress[0].fqdn, null) }
}

output "container_app_urls" {
  value = { for k, v in azurerm_container_app.apps : k => try("https://${v.ingress[0].fqdn}", null) }
}

output "latest_revision_names" {
  value = { for k, v in azurerm_container_app.apps : k => v.latest_revision_name }
}
