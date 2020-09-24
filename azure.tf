# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

#server azure
module "server_azure" {
  source                  = "./server_azure"
  public_key              = var.public_key
  server_count            = var.server_count_azure
  destination_port_ranges = var.destination_port_ranges
}
