terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.41.0"
    }
  }
}

# azure provider
provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
  name     = "rg-postgresql"
  location = "Australia East"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vn-postgresql"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "postgresql-subnet" {
  name                 = "sn-postgresql-delegated"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}



resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "devdcp.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link" {
  name                  = "dnsvnetlink-postgresqlvnet"
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
}

resource "azurerm_postgresql_flexible_server" "pgsql" {
  name                   = "pg-dcp-dev"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "12"
  delegated_subnet_id    = azurerm_subnet.postgresql-subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.dns_zone.id
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!"
  zone                   = "1"

  storage_mb = 32768

  sku_name   = "GP_Standard_D4s_v3"

  high_availability {
    mode = "ZoneRedundant"
    standby_availability_zone = "2"
  }


  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns_vnet_link]

}

resource "azurerm_postgresql_flexible_server_database" "psql-db" {
  name      = "example-db"
  server_id = azurerm_postgresql_flexible_server.pgsql.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
