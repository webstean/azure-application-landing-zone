# Andrew's module for creating an Azure Application Landing Zone
otherwise known as an environment (dev, test, sit, uat etc..)

[GitHub Repository](https://github.com/webstean/azure-application-landing-zone)

[Terraform Registry for this module](https://github.com/webstean/azure-application-landing-zone)

[Terraform Registry Home - my other modules](https://registry.terraform.io/namespaces/webstean)


[![Python][terraform-shield]][tf-version]
[![Latest][version-shield]][release-url]
[![Tests][test-shield]][test-url]
[![License][license-shield]][license-url]
<!-- [![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url] -->

This module creates what Microsoft's calls an [Application Landing Zone](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/ready) which you can think of an environment in which you applications and services can run, like DEV, TEST, SIT, UAT, PROD, etc.

This is apart of what Microsoft calls their [Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/what-is-well-architected-framework).

This module will deploy many different types of resources including, but not limited to:
- One Public DNS Zone (unless the variable always_create_private_link is set to "yes")
- One Virtual Network with preconfigure subnets and Bastion, which is used hosting resources in the Landing Zone
- Lots Private DNS for use with Private LInk (Only when the variable always_create_private_link is set to "yes")
- Two User Assigned Identities, one in intended for humans and the other for services/applications
- One Static Web App, for hosting static contect, such as information on the created landing zone
- One Log Analytics Workspace (including a "web" Application Insights) for logging, monitoring, alerting and debugging 
- One KeyVault which you should use, you should create your own KeyVault for secrets, such as passwords, certificates, etc.
- One SQL Server associated with one SQL Server Elastic Pool (these are free, until you put a database in them), configured for SQL Hyperscale
- One Cosmos DB Account
- One Azure Communication Service (ACS) for sending emails, SMSes and WhatsApp messages
- Three Storage Accounts (one for SQL Servers logs, one for files and one for the blobs)
- An Automation Account for running scripts, such as Azure CLI or PowerShell scripts either manually or via a schedule

and finally:
- One App Configuration preconfigured with all the landing zone deployments (SQL Server endpoints etc...)

You need to tell the module which Azure Resource Group to put everything in, as this won't be created by this module, in order to support [Azure Deployment Environments](https://learn.microsoft.com/en-us/azure/deployment-environments/overview-what-is-azure-deployment-environments)

Option, you can peer the Virtual Network into an existing vWAN Hub, which will allow you to connect to other Landing Zones and the Internet in general securelty via centralised infrastrucutre.
This infrastructure can be deployed via the 

> [!IMPORTANT]
> ❗ This is important 
>

> [!NOTE]
> ⚠️ Eventually this module will create an [Azure Network Perimeter](https://learn.microsoft.com/en-us/azure/private-link/network-security-perimeter-concepts) around everything in the Landing Zone, further isolating it from other Landing Zone and the Internet in general.
>

> [!CAUTION]
> ℹ️ This module creates lots of resources, that SHOULD cost zero to very little money, but things change! BE CAREFUL, so you don't get **Bill Shocks**
>

![Azure Landing Zone](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/media/azure-landing-zone-architecture-diagram-hub-spoke.svg#lightbox)


Example:
```hcl
module "application-landing-zone" {
  source  = "webstean/azure-application-landing-zone/azurerm"
  version = "~>0.0, < 1.0"

  ## identity
  user_assigned_identity_graph_name        = null
  user_assigned_identity_landing_zone_name = module.application_landing_zone.user_assigned_identity_name  ## (high-privilege) for services/applications
  entra_group_unified_id                   = null
  entra_group_pag_id                       = data.azuread_group.cloud_operators.id                        ## (low-privilege)  for humans/admin users
  
  ## naming
  resource_group_name               = data.azurerm_resource_group.lz.name
  landing_zone_name                 = "play"
  project_name                      = "main"
  application_name                  = "webstean"
  
  ## sizing
  sku_name                          = "free"          ## other options are: basic, standard, premium or isolated
  size_name                         = "small"         ## other options are: medium, large or x-large
  location_key                      = "australiaeast" ## other supported options are: australiasoutheast, australiacentral
  private_endpoints_always_deployed = false ## other option is: true

  ## these are just use for the tags to be applied to each resource
  owner_service        = "unknown@myorg.com"          ## business owner  - email address, used for visbility & alerts
  owner_tech           = "unknown@myorg.com"          ## business owner  - email address, used for visbility & alerts
  cost_centre          = "unknown"                    ## from the accountants, its the owner's cost centre. Freeform text
  monitoring           = "not-monitored"              ## other options are: 24-7 or 8-5
  ##
  subscription_id                   = data.azurerm_client_config.current.subscription_id
  keyvault_name = module.azure-application-landing-zone-keyvault.key_vault_name

}
```
---
## License

Distributed under the Mozilla Public License Version 2.0 License. See [LICENSE](./LICENSE) for more information.
