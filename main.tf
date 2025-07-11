## placeholder

## work out some basic variables
/*
locals {
  default_domain         = data.azuread_domains.default.domains[0].domain_name
  zone_balancing_enabled = var.sku_name == "premium" || var.sku_name == "isolated" ? true : false
  public_access_enabled  = var.data_pii == "yes" || var.data_pii == "yes" ? false : true
}
*/

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azuread_group" "this" {
  id = var.entra_group_id
}

