output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "key_vault_uri" {
  description = "The URI of the Azure Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "aca_environment_id" {
  description = "The ID of the Azure Container Apps Environment"
  value       = azurerm_container_app_environment.aca_env.id
}

output "aca_identity_id" {
  description = "The ID of the User Assigned Identity for ACA"
  value       = azurerm_user_assigned_identity.aca_identity.id
}

output "aca_identity_client_id" {
  description = "The Client ID of the User Assigned Identity for ACA"
  value       = azurerm_user_assigned_identity.aca_identity.client_id
}

output "postgres_fqdn" {
  description = "The internal DNS name of the PostgreSQL Container App"
  value       = "db-postgres"
}

output "backend_url" {
  description = "The public URL of the Backend Container App"
  value       = "https://${azurerm_container_app.backend_app.ingress[0].fqdn}"
}

output "frontend_url" {
  description = "The public URL of the Frontend Container App"
  value       = "https://${azurerm_container_app.frontend_app.ingress[0].fqdn}"
}
