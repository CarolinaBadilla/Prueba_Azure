data "azurerm_client_config" "current" {}

# checkov:skip=CKV_AZURE_42:Purge protection deshabilitado en dev para permitir destruccion limpia
# checkov:skip=CKV_AZURE_109:Acceso controlado via RBAC de Entra ID en entorno dev
# checkov:skip=CKV_AZURE_110:Purge protection deshabilitado en dev por ciclo de vida de laboratorio
# checkov:skip=CKV_AZURE_189:Private Endpoint omitido en dev por optimizacion FinOps
# checkov:skip=CKV2_AZURE_32:Private Endpoint omitido en dev por optimizacion FinOps
resource "azurerm_key_vault" "kv" {
  name                       = "kv-fullstack-${random_string.suffix.result}"
  location                   = azurerm_resource_group.app_rg.location
  resource_group_name        = azurerm_resource_group.app_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  tags                       = local.common_tags
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = "a6a7aec2-d11a-4922-9c55-566a7832be8f"
}
