terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod"
    storage_account_name = "sttfstatecaro2026"
    container_name       = "tfstate"
    key                  = "fullstack-app.tfstate"
    use_azuread_auth     = true
  }
}
