resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# checkov:skip=CKV_AZURE_139:SKU Basic requerido en dev por FinOps (Private Link exige SKU Premium)
# checkov:skip=CKV_AZURE_163:Escaneo de vulnerabilidades ejecutado en pipeline CI con Trivy
# checkov:skip=CKV_AZURE_164:Firma de imagenes omitida en entorno dev
# checkov:skip=CKV_AZURE_165:Geo-replicacion omitida en entorno dev por FinOps
# checkov:skip=CKV_AZURE_166:Cuarentena de imagenes omitida en dev
# checkov:skip=CKV_AZURE_167:Politica de retencion solo disponible en SKU Premium
# checkov:skip=CKV_AZURE_233:Redundancia de zona omitida en dev por FinOps
# checkov:skip=CKV_AZURE_237:Endpoints dedicados solo disponibles en SKU Premium
resource "azurerm_container_registry" "acr" {
  name                = "acrfullstack${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.common_tags
}
