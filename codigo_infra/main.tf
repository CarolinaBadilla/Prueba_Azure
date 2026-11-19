locals {
  common_tags = {
    Environment = "dev"
    Owner       = "Carolina"
    CostCenter  = "Cloud-Portfolio"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "app_rg" {
  name     = "rg-fullstack-dev-eastus2"
  location = "eastus2"
  tags = {
     Environment = "dev"
     ManagedBy   = "Terraform-GitOps"
   }
}
