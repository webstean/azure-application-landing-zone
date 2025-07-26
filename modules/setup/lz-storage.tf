## Each Application and Landing Zone module will have 3 Storage Accounts
## sql - dedicated to SQL Server logging
## blob - dedicated to blobs, for use throughout the landing zone
## file - dedicated to blobs, for use throughout the landing zone

module "storage-sql" {
  source           = "webstean/storage-account/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  ## Identity
  entra_group_pag_id = var.entra_group_pag_id
  user_managed_name  = var.user_assigned_identity_name

  ## Naming 
  dns_zone_name     = var.dns_zone_name
  landing_zone_name = var.landing_zone_name
  project_name      = "lz"
  application_name  = "sql"

  ## SKUs and Sizes
  sku_name  = var.sku_name
  size_name = var.size_name

  ## Location
  subscription_id     = var.subscription_id
  location_key        = var.location_key
  resource_group_name = var.resource_group_name

  ## Tags / Naming
  owner       = var.owner
  cost_centre = var.cost_centre
  monitoring  = var.monitoring

  type = "blob"
  // options are: LRS, GRS, ZRS, RAGRS, RA-GRS, GZRS, RA-GZRS
  storage_replication_type = (var.sku_name == "premium" || var.sku_name == "isolated") ? "GRS" : "LRS"
}

module "storage-blob" {
  source           = "webstean/storage-account/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  ## Identity
  entra_group_pag_id = var.entra_group_pag_id
  user_managed_name  = var.user_assigned_identity_name

  ## Naming 
  dns_zone_name     = var.dns_zone_name
  landing_zone_name = var.landing_zone_name
  project_name      = "lz"
  application_name  = "blob"

  ## SKUs and Sizes
  sku_name  = var.sku_name
  size_name = var.size_name

  ## Location
  subscription_id     = var.subscription_id
  location_key        = var.location_key
  resource_group_name = var.resource_group_name

  ## Tags / Naming
  owner       = var.owner
  cost_centre = var.cost_centre
  monitoring  = var.monitoring

  type = "blob"
  // options are: LRS, GRS, ZRS, RAGRS, RA-GRS, GZRS, RA-GZRS
  storage_replication_type = (var.sku_name == "premium" || var.sku_name == "isolated") ? "GRS" : "LRS"
}

module "storage-file" {
  source           = "webstean/storage-account/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  ## Identity
  entra_group_pag_id = var.entra_group_pag_id
  user_managed_name  = var.user_assigned_identity_name

  ## Naming 
  dns_zone_name     = var.dns_zone_name
  landing_zone_name = var.landing_zone_name
  project_name      = "lz"
  application_name  = "file"

  ## SKUs and Sizes
  sku_name  = var.sku_name
  size_name = var.size_name

  ## Location
  subscription_id     = var.subscription_id
  location_key        = var.location_key
  resource_group_name = var.resource_group_name

  ## Tags / Naming
  owner       = var.owner
  cost_centre = var.cost_centre
  monitoring  = var.monitoring

  type = "file"
  // options are: LRS, GRS, ZRS, RAGRS, RA-GRS, GZRS, RA-GZRS
  storage_replication_type = (var.sku_name == "premium" || var.sku_name == "isolated") ? "GRS" : "LRS"
}
