## landing-zone module
## check the input variables are actually valid

## this has to already exist, you cannot create it here
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azuread_group" "this" {
  object_id = startswith(var.entra_group_id, "/groups/") ? substr(var.entra_group_id, 8, -1) : var.entra_group_pag_id
}

data "azurerm_user_assigned_identity" "this" {
  name                = var.user_assigned_identity_name
  resource_group_name = var.resource_group_name
}

module "lz-init" {
  ## Creates the initial landing zone resources, such the Azure Key Vault, Identities, Backup & public and private DNS zone (only if var.private_endpoints_always_deployed == true)
  source  = "./init/"

  ## Naming 
  landing_zone_name    = var.landing_zone_name
  dns_zone_name        = var.dns_zone_name

  ## SKUs and Sizes
  sku_name             = var.sku_name
  size_name            = var.size_name

  ## Security
  private_endpoints_always_deployed = var.private_endpoints_always_deployed

  ## Location
  subscription_id      = var.subscription_id
  location_key         = var.location_key
  resource_group_name  = var.resource_group_name

  ## Tags / Naming
  owner                = var.owner
  cost_centre          = var.cost_centre
  monitoring           = var.monitoring
  org_fullname         = var.org_fullname
  org_shortname        = var.org_shortname
}

module "lz-setup" {
  ## Creates the storage accounts
  source  = "./setup/"

  ## Naming 
  landing_zone_name    = module.lz-init.landing_zone_name
  dns_zone_name        = module.lz-init.dns_zone_name

  ## Identity
  entra_group_pag_id                      = module.lz-init.entra_group_pag_id
  user_assigned_identity_graph_id         = module.lz-init.user_assigned_identity_graph_id
  user_assigned_identity_landing_zone_id  = module.lz-init.user_assigned_identity_landing_zone_id

  ## SKUs and Sizes
  sku_name             = module.lz-init.landing_zone_name.sku_name
  size_name            = module.lz-init.landing_zone_name.size_name

  ## Security
  private_endpoints_always_deployed = var.private_endpoints_always_deployed

  ## Location
  subscription_id      = module.lz-init.subscription_id
  location_key         = module.lz-init.location_key
  resource_group_name  = module.lz-init.resource_group_name

  ## Tags / Naming
  owner                = module.lz-init.owner
  cost_centre          = module.lz-init.cost_centre
  monitoring           = module.lz-init.monitoring
  org_fullname         = module.lz-init.org_fullname
  org_shortname        = module.lz-init.org_shortname
}

