# Define important local variables
locals {

  # Define delegation actions for various services
  delegation_actions = toset([
    "Microsoft.Network/virtualNetworks/subnets/join/action",
  ])

  delegation_full_actions = toset([
    "Microsoft.Network/networkinterfaces/*",
    "Microsoft.Network/publicIPAddresses/join/action",
    "Microsoft.Network/publicIPAddresses/read",
    "Microsoft.Network/virtualNetworks/read",
    "Microsoft.Network/virtualNetworks/subnets/action",
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
    "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
  ])

  # This local var has been removed, use delegation_actions instead
  # delegation-actions = toset([
  #     "Microsoft.Network/networkinterfaces/*",
  #     "Microsoft.Network/virtualNetworks/subnets/join/action",
  #     "Microsoft.Network/virtualNetworks/subnets/action",
  # ])

  service_endpoints_full = toset([
    "Microsoft.AzureActiveDirectory",
    "Microsoft.AzureCosmosDB",
    "Microsoft.CognitiveServices",
    "Microsoft.ContainerRegistry", // still in preview
    "Microsoft.EventHub",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    //    "Microsoft.Storage", ## not supported when Microsoft.Storage.Global is in use
    "Microsoft.Storage.Global",
    "Microsoft.Sql",
    "Microsoft.Web",
  ])

  ## Should be change to: "Direct" "NAT-Gateway", "Firewall"
  outbound_internet_access = "Direct"
  ## var.data_pii == "yes" || var.data_phi == "yes" ? false : true
}

# allow policy
resource "azurerm_subnet_service_endpoint_storage_policy" "this" {
  name                = "sep-${module.naming.unique-seed}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  definition {
    name = "name1"
    service_resources = [
      data.azurerm_resource_group.this.id,
      ## azurerm_storage_account.this.id
    ]
    description = "definition1"
    service     = "Microsoft.Storage"
  }
  tags = data.azurerm_resource_group.this.tags
  lifecycle {
    ignore_changes = [
      tags.created,
    ]
  }
}


module "virutal_network" {
  source           = "Azure/avm-res-network-virtualnetwork/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  name                = each.value.virtual_network.name_unique
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  address_space = local.regions[each.key].vnet_address_space

  encryption = {
    enabled = var.data_pii == "yes" || var.data_phi == "yes" ? true : false
    #enforcement = "DropUnencrypted"  # NOTE: This preview feature requires approval, leaving off in example: Microsoft.Network/AllowDropUnecryptedVnet
    enforcement = "AllowUnencrypted"
  }

  flow_timeout_in_minutes = 30
  bgp_community           = local.regions[var.location_key].vnet_bgp_community
  ## dns_servers       = "${local.regions[each.key].dns_servers}"

  #ddos_protection_plan = {
  #  id = azurerm_network_ddos_protection_plan.this.id
  #  # due to resource cost
  #  enable = false
  ## enable = var.data_pii == "yes" || var.data_phi == "yes" ? true : false
  #}

  diagnostic_settings = {
    sendToLogAnalytics = {
      name                           = "sendToLogAnalytics"
      workspace_resource_id          = azurerm_log_analytics_workspace.this.id ## this does not exist yet
      log_analytics_destination_type = "Dedicated"
    }
  }

  subnets = {
    bastion = { ## Azure Bastion
      name = "AzureBastionSubnet"
      address_prefixes = [
        format("10.%s.66.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.bastion.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = "Disabled"
      delegation = [{
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = local.delegation_actions
        }
      }]
    }

    aca = { ## Azure Container App
      name = "aca"
      address_prefixes = [
        format("10.%s.10.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = local.delegation_actions
        }
      }]
    }

    aci = { ## Azure Container Instances
      name = "aci"
      address_prefixes = [
        format("10.%s.20.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.ContainerInstance/containerGroups"
          actions = local.delegation_actions
        }
      }]
    }
    powerplatform-connectivity = { ## Power Platform
      name = "powerplatform-connectivity"
      address_prefixes = [
        format("10.%s.50.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.PowerPlatform/enterprisePolicies"
          actions = local.delegation_actions
        }
      }]
    }
    powerplatform-gateways = { ## Power Platform
      name = "powerplatform-gateways"
      address_prefixes = [
        format("10.%s.55.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = "Disabled"
      delegation = [{
        service_delegation = {
          name    = "Microsoft.PowerPlatform/vnetaccesslinks"
          actions = local.delegation_actions
        }
      }]
    }
    appserviceplan-windows = { ## App Service Plan - Windows
      name = "appserviceplan-windows"
      address_prefixes = [
        format("10.%s.101.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = "Disabled"
      delegation = [{
        service_delegation = {
          name    = "Microsoft.Web/hostingEnvironments"
          actions = local.delegation_actions
        }
      }]
    }
    appserviceplan-linux = { ## App Service Plan - Linux
      name = "appserviceplan-linux"
      address_prefixes = [
        format("10.%s.102.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = "Disabled"
      delegation = [{
        service_delegation = {
          name    = "Microsoft.Web/hostingEnvironments"
          actions = local.delegation_actions
        }
      }]
    }

    appservice-environment-windows = { ## App Service Environment - Windows
      name = "appservice-environment-windows"
      address_prefixes = [
        format("10.%s.110.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = "Disabled"
      delegation = [{
        service_delegation = {
          name    = "Microsoft.Web/hostingEnvironments"
          actions = local.delegation_actions
        }
      }]
    }

    appservice-environment-linux = { ## App Service Environment - Linux
      name = "appservice-environment-linux"
      address_prefixes = [
        format("10.%s.111.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.Web/hostingEnvironments"
          actions = local.delegation_actions
        }
      }]
    }

    logicapps = { ## Logic Apps
      name = "logicapps"
      address_prefixes = [
        format("10.%s.115.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.Logic/integrationServiceEnvironments"
          actions = local.delegation_actions
        }
      }]
    }

    windows-vm = { ## Windows VM`
      name = "windows-vm"
      address_prefixes = [
        format("10.%s.120.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = null
    }

    linux-vm = { ## Linux VM
      name = "linux-vm"
      address_prefixes = [
        format("10.%s.125.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = null
    }


    integration = { ## Service Bus, Event Gird, Event Hub etc..
      name = "integration"
      address_prefixes = [
        format("10.%s.150.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      service_delegation = []
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = null
    }

    sentinel = { ## Sentinel related, like a syslog relay VM
      name = "sentinel"
      address_prefixes = [
        format("10.%s.166.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = null
    }

    private-link-service = { ## Private Link Service
      name = "private-link-service"
      address_prefixes = [
        format("10.%s.170.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = null
    }

    private-endpoints = { ## Private Endpoints
      name = "private-endpoints"
      address_prefixes = [
        format("10.%s.180.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = null
    }

    oracle = { ## Oracle
      name = "oracle"
      address_prefixes = [
        format("10.%s.190.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = {
        service_delegation = {
          name    = "Oracle.Database/networkAttachments"
          actions = local.delegation_actions
        }
      }
    }

    api-management = { ## API Management
      name = "api-management"
      address_prefixes = [
        format("10.%s.200.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.ApiManagement/service"
          actions = local.delegation_actions
        }
      }]
    }

    fhir = { ## Health APIs
      name = "fhir"
      address_prefixes = [
        format("10.%s.210.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      service_delegation = ["Microsoft.Sql/servers"]
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = null
    }

    machine-learning = { ## Machine Learning Workspaces
      name = "machine-learning"
      address_prefixes = [
        format("10.%s.220.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.MachineLearningServices/workspaces"
          actions = local.delegation_actions
        }
      }]
    }

    nginx = { ## nginx PaaS from Microsoft/nginx
      name = "nginx"
      address_prefixes = [
        format("10.%s.230.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "NGINX.NGINXPLUS/nginxDeployments"
          actions = local.delegation_actions
        }
      }]
    }

    ado-infra = { ## DevOps (ADO) Infrastructure - pipelines
      name = "ado-infra"
      address_prefixes = [
        format("10.%s.232.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.DevOpsInfrastructure/pools"
          actions = local.delegation_actions
        }
      }]
    }

    github-infra = { ## GitHub Infrastructure - runners
      name = "github-infra"
      address_prefixes = [
        format("10.%s.234.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "GitHub.Network/networkSettings"
          actions = local.delegation_actions
        }
      }]
    }

    IoT = { ## Internet of Things - CCTV, door controllers, facilities (temperature, humidity, pressure etc..)
      name = "IoT"
      address_prefixes = [
        format("10.%s.236.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = null
    }

    IoMT = { ## Internet of Medical Things
      name = "IoMT"
      address_prefixes = [
        format("10.%s.238.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null

      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = "Disabled"
      delegation                        = null
    }

    sqlserver = { ## Azure SQL Server
      name = "sqlserver"
      address_prefixes = [
        format("10.%s.240.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? ["Microsoft.Sql", "Microsoft.Storage"] : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = null
    }

    cosmos = { ## Cosmos
      name = "cosmos"
      address_prefixes = [
        format("10.%s.245.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? ["Microsoft.AzureCosmosDB", "Microsoft.Storage"] : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.AzureCosmosDB/clusters"
          actions = local.delegation_actions
        }
      }]
    }

    devbox = { ## DevBox - Developers, SRE, DevOps workspaces
      name = "devbox"
      address_prefixes = [
        format("10.%s.250.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      network_security_group = {
        id = azurerm_network_security_group.anytcp.id
      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.DevCenter/networkConnection"
          actions = local.delegation_actions
        }
      }]
    }

    // Azure Services - names are mandatory
    GatewaySubnet = { ## Azure Gateways
      name = "GatewaySubnet"
      address_prefixes = [
        format("10.%s.251.0/24", local.regions[each.key].location_number),
      ]
      service_endpoints               = var.private_endpoints_always_deployed != true ? local.service_endpoints_full : null
      default_outbound_access_enabled = var.private_endpoints_always_deployed == true ? false : true
      #      network_security_group = {
      #        id = azurerm_network_security_group.test[each.key].id
      #      }
      service_endpoint_policies = var.private_endpoints_always_deployed != true ? {
        policy1 = {
          id = azurerm_subnet_service_endpoint_storage_policy.this.id
        }
      } : null
      ## Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled.
      private_endpoint_network_policies = var.private_endpoints_always_deployed == true ? "NetworkSecurityGroupEnabled" : "Disabled"

      delegation = [{
        service_delegation = {
          name    = "Microsoft.Network/virtualNetworkGateways"
          actions = local.delegation_actions
        }
      }]
    }

  }
  lock = (local.contains_real_data) ? {
    kind = local.lock_kind
    name = local.iac_message
  } : null

  timeouts = {
    create = "60m"
    update = "60m"
    read   = "60m"
    delete = "60m"
  }

  tags = data.azurerm_resource_group.this.tags
}

/*
locals {
  ## subnet id for service endpoints
  application_subnet_ids = [
    for subnet in azurerm_subnet.application_subnets :
    subnet.id
  ]
  ## only include subnets that are not used for PII/PHI data
  conditional_application_subnet_ids = (var.data_pii == "yes" || var.data_phi == "yes") ? [] : [
    for subnet in azurerm_subnet.application_subnets : subnet.id
  ]
  storage_service_endpoint_subnets_ids = (var.data_pii == "yes" || var.data_phi == "yes") ? [] : [
    for subnet in azurerm_subnet.application_subnets : subnet.id
    if subnet.service_endpoints != null && contains(subnet.service_endpoints, "Microsoft.Storage.Global")
  ]
  container_registry_service_endpoint_subnets_ids = (var.data_pii == "yes" || var.data_phi == "yes") ? [] : [
    for subnet in azurerm_subnet.application_subnets : subnet.id
    if subnet.service_endpoints != null && contains(tolist(subnet.service_endpoints), "Microsoft.ContainerRegistry")
  ]
  cosmos_service_endpoint_subnets_ids = (var.data_pii == "yes" || var.data_phi == "yes") ? [] : [
    for subnet in azurerm_subnet.application_subnets : subnet.id
    if subnet.service_endpoints != null && contains(tolist(subnet.service_endpoints), "Microsoft.AzureCosmosDB")
  ]
  eventhub_service_endpoint_subnets_ids = (var.data_pii == "yes" || var.data_phi == "yes") ? [] : [
    for subnet in azurerm_subnet.application_subnets : subnet.id
    if subnet.service_endpoints != null && contains(tolist(subnet.service_endpoints), "Microsoft.EventHub")
  ]
  keyvault_service_endpoint_subnets_ids = (var.data_pii == "yes" || var.data_phi == "yes") ? [] : [
    for subnet in azurerm_subnet.application_subnets : subnet.id
    if subnet.service_endpoints != null && contains(tolist(subnet.service_endpoints), "Microsoft.KeyVault")
  ]
  servicebus_service_endpoint_subnets_ids = (var.data_pii == "yes" || var.data_phi == "yes") ? [] : [
    for subnet in azurerm_subnet.application_subnets : subnet.id
    if subnet.service_endpoints != null && contains(tolist(subnet.service_endpoints), "Microsoft.ServiceBus")
  ]
  sql_server_endpoint_subnets_ids = (var.data_pii == "yes" || var.data_phi == "yes") ? [] : [
    for subnet in azurerm_subnet.application_subnets : subnet.id
    if subnet.service_endpoints != null && contains(tolist(subnet.service_endpoints), "Microsoft.Sql")
  ]
  web_service_endpoint_subnets_ids = (var.data_pii == "yes" || var.data_phi == "yes") ? [] : [
    for subnet in azurerm_subnet.application_subnets : subnet.id
    if subnet.service_endpoints != null && contains(tolist(subnet.service_endpoints), "Microsoft.Web") // Azure App Services)
  ]
}
*/

/*
output "virtual_network_subnet_service_endpoints" {
  description = "Map of subnet IDs with their enabled service endpoints"
  value = {
    "Microsoft.Storage"           = null
    "Microsoft.Storage.Global"    = local.storage_service_endpoint_subnets_ids
    "Microsoft.ContainerRegistry" = local.container_registry_service_endpoint_subnets_ids
    "Microsoft.AzureCosmosDB"     = local.cosmos_service_endpoint_subnets_ids
    "Microsoft.EventHub"          = local.eventhub_service_endpoint_subnets_ids
    "Microsoft.KeyVault"          = local.keyvault_service_endpoint_subnets_ids
    "Microsoft.ServiceBus"        = local.servicebus_service_endpoint_subnets_ids
    "Microsoft.Sql"               = local.sql_server_endpoint_subnets_ids
    "Microsoft.Web"               = local.web_service_endpoint_subnets_ids
  }
}
*/

output "virtual_network_subnet_ids" {
  description = "Map of subnet IDs with their types"
  value = {
    for subnet in module.virtual_network.subnets :
    subnet.name => subnet.id
  }
}
output "virtual_network_id" {
  description = "Map of virtual network IDs with their names"
  value       = module.virtual_network.resource.id
}

resource "azurerm_public_ip" "vnet-nat-gateway" {
  count = local.outbound_internet_access == "NAT-Gateway" ? 1 : 0

  name                = "pip-${var.landing_zone_name}-${local.regions[var.location_key].shortname}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = local.regions[var.location_key].location
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_nat_gateway" "vnet-nat-gateway" {
  count = local.outbound_internet_access == "NAT-Gateway" ? 1 : 0

  name                = "nat-${var.landing_zone_name}-${local.regions[var.location_key].shortname}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = local.regions[var.location_key].location
  sku_name            = "Standard"
  zones               = (var.sku_name == "premium" || var.sku_name == "isolated") && (local.regions[var.location_key].zone_redundancy_available == true) ? local.regions[var.location_key].zones : null
  tags                = azurerm_virtual_network.vnet[var.location_key].tags

}
resource "azurerm_nat_gateway_public_ip_association" "vnet-nat-gateway" {
  count = local.outbound_internet_access == "NAT-Gateway" ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.vnet-nat-gateway[count.index].id
  public_ip_address_id = azurerm_public_ip.vnet-nat-gateway[count.index].id
}
resource "azurerm_subnet_nat_gateway_association" "vnet-nat-gateway" {
  for_each = local.outbound_internet_access == "NAT-Gateway" ? data.azurerm_subnet.application_subnets : {}

  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.vnet-nat-gateway[0].id
}

