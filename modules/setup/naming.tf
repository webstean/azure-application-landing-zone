resource "random_string" "naming_seed" {
  length  = 7
  lower   = true
  upper   = false
  special = false
}

## https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs
## Hopefully, will be replace by avm-utl-naming https://registry.terraform.io/modules/Azure/avm-utl-naming/azure/latest
module "naming-global" {
  for_each = { for k, v in local.regions : k => v if k == var.location_key }

  source  = "Azure/naming/azurerm"
  version = "~>0.0, < 1.0"

  suffix = [lower(var.org_shortname), lower("global"), lower(each.value.short_name)]

  unique-seed = random_string.naming_seed.result
}

module "naming-landing-zone" {
  for_each = { for k, v in local.regions : k => v if k == var.location_key }

  source  = "Azure/naming/azurerm"
  version = "~>0.0, < 1.0"

  suffix = [lower(var.org_shortname), lower("lz"), lower(var.landing_zone_name), lower(each.value.short_name)]

  unique-seed = random_string.naming_seed.result
}
