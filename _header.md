# Andrew's Terraform module for creating an Azure Application Landing Zone
otherwise known as an environment (dev, test, sit, uat etc..)

[GitHub Repository](https://github.com/webstean/azure-application-landing-zone)

[Terraform Registry for this module](https://github.com/webstean/azure-application-landing-zone)

[Terraform Registry Home - my other modules](https://registry.terraform.io/namespaces/webstean)


This module creates what Microsoft's calls an [Application Landing Zone](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/ready) which you can think of an environment in which you applications and services can run, like DEV, TEST, SIT, UAT, PROD, etc.

This include main different types of resources including, but not limited to:
- One Public DNS Zone (unless the variable always_create_private_link is set to "yes")
- Lots Private DNS for use with Private LInk (Only when the variable always_create_private_link is set to "yes")
- Two User Assigned Identities, one in intended for humans and the other for services/applications
- One Static Web App, for hosting static contect, such as information on the created landing zone
- One Log Analytics Workspace (including a "web" Application Insights) for logging, monitoring, alerting and debugging 
- One KeyVault which you should use, you should create your own KeyVault for secrets, such as passwords, certificates, etc.
- One SQL Server associated with one SQL Server Elastic Pool (these are free, until you put a database in them), configured for SQL Hyperscale
- One Cosmos DB Account
- One Azure Communication Service (ACS) for sending emails, SMSes and WhatsApp messages
- Three Storage Accounts (one for SQL Servers logs, one for files and one for the blobs)

You need to tell the module which Azure Resource Group to put everytihng in, as this won't be created by this module, in order to support [Azure Deployment Environments](https://learn.microsoft.com/en-us/azure/deployment-environments/overview-what-is-azure-deployment-environments)


> [!IMPORTANT]
> ❗ This is important 
>

> [!NOTE]
> ⚠️ Eventually this module will create an [Azure Network Perimeter](https://learn.microsoft.com/en-us/azure/private-link/network-security-perimeter-concepts) around everything in the Landing Zone, further isolating it from other Landing Zone and the Internet in general.
>

> [!CAUTION]
> ℹ️ This module creates lots of resources, that SHOULD cost zero to very little money, but things change! BE CAREFUL, so you don't get **Bill Shocks**
>


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
