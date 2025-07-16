# Andrew's Azure Terraform module for creating an Azure Application Landing Zone
otherwise known as an environment (dev, test, sit, uat etc..)

[GitHub Repository](https://github.com/webstean/azure-application-landing-zone)

[Terraform Registry for this module](https://github.com/webstean/azure-application-landing-zone)

[Terraform Registry Home - my other modules](https://registry.terraform.io/namespaces/webstean)


This module creats what Microsoft's calls an [Application Landing Zone](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/ready) which you can think of an environment in which you applications and services can run, like DEV, TEST, SIT, UAT, PROD, etc.

> [!IMPORTANT]
> This is important
>

> [!INFO]
> This is info

> [!NOTE]
> This is a note

> [!CAUTION]
> This is caution

> [!DANGER]
> This module creates lots of resources, that SHOULD cost zero to very little moneny, but things change! BE CAREFUL, so you don't get **Bill Shocks**


Example:
```hcl
module "application-landing-zone" {
  source  = "webstean/azure-application-landing-zone/azurerm"
  version = "~>0.0, < 1.0"

  ## identity
  user_managed_id     = module.application_landing_zone.user_managed_id     ## services/applications
  entra_group_id      = azuread_group.cloud_operators.id                    ## humans/admin users
  
  ## naming
  resource_group_name = module.application_landing_zone.resource_group_name
  landing_zone_name   = "play"
  project_name        = "main"
  application_name    = "webstean"
  
  ## sizing
  sku_name            = "free"          ## other options are: basic, standard, premium or isolated
  size_name           = "small"         ## other options are: medium, large or x-large
  location_key        = "australiaeast" ## other supported options are: australiasoutheast, australiacentral
  private_endpoints_always_deployed = false ## other option is: true
  ## these are just use for the tags to be applied to each resource
  owner               = "tbd"           ## freeform text, but should be a person or team, email address is ideal
  cost_centre         = "unknown"       ## from the accountants, its the owner's cost centre
  ##
  subscription_id     = data.azurerm_client_config.current.subscription_id
  special = "special"

}
```
---
