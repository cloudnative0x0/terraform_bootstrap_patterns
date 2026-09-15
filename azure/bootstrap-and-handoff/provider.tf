provider "azurerm" {
  alias               = "global"
  subscription_id     = var.subscription_ids["global"]
  tenant_id           = var.tenant_id
  storage_use_azuread = true
  features {}
}
provider "azurerm" {
  alias               = "core_dev"
  subscription_id     = var.subscription_ids["core_dev"]
  tenant_id           = var.tenant_id
  storage_use_azuread = true
  features {}
}
provider "azurerm" {
  alias               = "core_prod"
  subscription_id     = var.subscription_ids["core_prod"]
  tenant_id           = var.tenant_id
  storage_use_azuread = true
  features {}
}
provider "azurerm" {
  alias               = "shared_network_dev"
  subscription_id     = var.subscription_ids["shared_network_dev"]
  tenant_id           = var.tenant_id
  storage_use_azuread = true
  features {}
}
provider "azurerm" {
  alias               = "shared_network_prod"
  subscription_id     = var.subscription_ids["shared_network_prod"]
  tenant_id           = var.tenant_id
  storage_use_azuread = true
  features {}
}
