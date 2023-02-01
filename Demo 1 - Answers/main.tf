# terraform block
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.41.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
}


resource "azurerm_resource_group" "rg" {
  name     = "rg-demo1"
  location = "Australia East"
}