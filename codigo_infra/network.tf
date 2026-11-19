resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-fullstack-dev"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "snet_aca" {
  name                 = "snet-aca"
  resource_group_name  = azurerm_resource_group.app_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/23"]

  delegation {
    name = "delegation-aca"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_network_security_group" "nsg_aca" {
  name                = "nsg-aca-dev"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  tags                = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "snet_aca_nsg" {
  subnet_id                 = azurerm_subnet.snet_aca.id
  network_security_group_id = azurerm_network_security_group.nsg_aca.id
}

resource "azurerm_subnet" "snet_db" {
  name                 = "snet-db"
  resource_group_name  = azurerm_resource_group.app_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-db-dev"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  tags                = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "snet_db_nsg" {
  subnet_id                 = azurerm_subnet.snet_db.id
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}
