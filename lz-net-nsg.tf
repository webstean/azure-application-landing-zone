
### Azure Service Tags: https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview

/* 
NSG Rules for AzureBastionSubnet association. Not providing required rules will 
not allow resource to build and will result in an error.
*/

/*
default = {
    #ActiveDirectory
    ActiveDirectory-AllowSMTPReplication        = ["Inbound", "Allow", "Tcp", "*", "25", "AllowSMTPReplication"]
    ActiveDirectory-AllowRPCReplication         = ["Inbound", "Allow", "Tcp", "*", "135", "AllowRPCReplication"]
    ActiveDirectory-AllowFileReplication        = ["Inbound", "Allow", "Tcp", "*", "5722", "AllowFileReplication"]
    ActiveDirectory-AllowWindowsTime            = ["Inbound", "Allow", "Udp", "*", "123", "AllowWindowsTime"]
    ActiveDirectory-AllowPasswordChangeKerberes = ["Inbound", "Allow", "*", "*", "464", "AllowPasswordChangeKerberes"]
    ActiveDirectory-AllowDFSGroupPolicy         = ["Inbound", "Allow", "Udp", "*", "138", "AllowDFSGroupPolicy"]
    ActiveDirectory-AllowADDSWebServices        = ["Inbound", "Allow", "Tcp", "*", "9389", "AllowADDSWebServices"]
  
    #DynamicPorts
    DynamicPorts = ["Inbound", "Allow", "Tcp", "*", "49152-65535", "DynamicPorts"]


  }
  description = "Standard set of predefined rules"
}
*/


### https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg

### https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview

# Fetching the public IP address of the Terraform executor used for NSG
data "http" "public_ip" {
  method = "GET"
  url    = "http://api.ipify.org?format=json"
}

/*
security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    direction                  = "Inbound"
    name                       = "AllowInboundHTTPSforTerraform"
    priority                   = 100
    protocol                   = "Tcp"
    source_address_prefix      = jsondecode(data.http.public_ip.response_body).ip
    source_port_range          = "*"
  }
*/

resource "azurerm_network_security_group" "any" {
  name                = "nsg-${var.landing_zone_name}-${local.regions[var.location_key].short_name}-any"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  ## Inbound: Allow All
  security_rule {
    name                       = "Allow-Any-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Inbound Allow Any from Anywhere"
  }
  ## Outbound: Allow All
  security_rule {
    name                       = "Allow-Any-Outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Outbound Allow Any to Anywhere"
  }

  tags = data.azurerm_resource_group.this.tags
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags.created]
  }
}

resource "azurerm_network_security_group" "anytcp" {
  name                = "nsg-${var.landing_zone_name}-${local.regions[var.location_key].short_name}-anytcp"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  ## Inbound: Allow All
  security_rule {
    name                       = "Allow-Any-TCP-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Inbound Allow Any TCP from Anywhere"
  }
  ## Outbound: Allow All
  security_rule {
    name                       = "Allow-Any-TCP-Outbound"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Outbound Allow Any TCP to Anywhere"
  }

  tags = data.azurerm_resource_group.this.tags
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags.created]
  }
}

resource "azurerm_network_security_group" "tls" {
  name                = "nsg-${var.landing_zone_name}-${local.regions[each.value.location].short_name}-any-tls"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  security_rule {
    name                       = "AllowHttps-from-LoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "LoadBalancer"
    description                = "Inbound AllowHttps from Internet"
  }
  security_rule {
    name                       = "AllowHttps-from-GatewayManager"
    priority                   = 111
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "VirtualNetwork"
    description                = "Inbound AllowHttps from Internet"
  }
  security_rule {
    name                       = "AllowHttps-from-Internet"
    priority                   = 112
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
    description                = "Inbound AllowHttps from Internet"
  }
  security_rule {
    name                       = "AllowHttps-plus-Debugging-via-VirtualNetwork"
    priority                   = 113
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80", "443", "4024", "5000", "5001", "5005", "5006", "5678", "8080", "8443", "9222", "9229", "9230"] ## extra ports for debugging
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Inbound AllowHttps from Internal - plus standard debugging TCP ports"
  }

  ## Outbound: AzureAustraliaEast
  security_rule {
    name                       = "Allow-Azure-AustraliaEast"
    priority                   = 606
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiaeast"
    description                = "Allow Azure Cloud, but just Australia East region"
  }
  ## Outbound: AzureAustraliaSouthEast
  security_rule {
    name                       = "Allow-Azure-AustraliaSouthEast"
    priority                   = 607
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiasoutheast"
    description                = "Allow Azure Cloud, but just Australia Southeast region"
  }
  ## Outbound: AzureAustraliaCentral1
  security_rule {
    name                       = "Allow-Azure-AustraliaCentral"
    priority                   = 608
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiacentral"
    description                = "Allow Azure Cloud, but just Australia Central1 region"
  }
  ## Outbound: AzureAustraliaCentral2
  security_rule {
    name                       = "Allow-Azure-AustraliaCentral2"
    priority                   = 609
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiacentral2"
    description                = "Allow Azure Cloud, but just Australia Central2 region"
  }
  ## Outbound: AzureSouthAsia
  security_rule {
    name                       = "Allow-Azure-SouthEastAsia"
    priority                   = 610
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.southeastasia"
    description                = "Allow Azure Cloud, but just South Asia (Singapore) for Static Web App (not hosted in Australian regions)"
  }

  ## Outbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Inbound as part of Zero Trust Networking"
  }

  ## Inbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Outound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Allow" ## needs to be "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Outbound as part of Zero Trust Networking"
  }

  tags = each.value.tags
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags.created]
  }
}

## for Basion SKU, except Developer, intended to be applied to the AzureBastionSubnet
resource "azurerm_network_security_group" "bastion" {
  for_each = local.bastion_sku == "Developer" ? {} : azurerm_virtual_network.vnet

  name                = "nsg-${var.landing_zone_name}-${local.regions[each.value.location].short_name}-bastion"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  ### Ingress Traffic from public internet:
  ### The Azure Bastion will create a public IP that needs port 443 enabled on the public IP for ingress traffic.
  ### Port 3389/22 are NOT required to be opened on the AzureBastionSubnet.
  ### Note that the source can be either the Internet or a set of public IP addresses that you specify.
  security_rule {
    name                       = "Inbound-AllowHttps-from-Internet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    description                = "Inbound AllowHttps from Internet"
  }

  ### Ingress Traffic from Azure Bastion control plane:
  ### For control plane connectivity, enable port 443 inbound from GatewayManager service tag.
  ### This enables the control plane, that is, Gateway Manager to be able to talk to Azure Bastion.
  security_rule {
    name                       = "Inbound-AllowHttps-from-GatewayManager"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
    description                = "Inbound AllowHttps from Bastion Control Plane (GatewayManager)"
  }

  ### Ingress Traffic from Azure Bastion data plane:
  ### For data plane communication between the underlying components of Azure Bastion,
  ### enable ports 8080, 5701 inbound from the VirtualNetwork service tag to the VirtualNetwork service tag.
  ### This enables the components of Azure Bastion to talk to each other.
  security_rule {
    name                       = "Inbound-Bastion-Vnet"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Inbound Control Plane for Bastion"
  }
  ### Ingress Traffic from Azure Load Balancer:
  ### For health probes, enable port 443 inbound from the AzureLoadBalancer service tag.
  ### This enables Azure Load Balancer to detect connectivity
  security_rule {
    name                       = "Inbound-AllowHttps-from-AzureLoadBalancer"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    description                = "Allow Inbound Https from Azure Load Balancer (for Bastion)"
  }

  security_rule {
    name                       = "Outbound-Bastion-Vnet"
    priority                   = 160
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Outbound Bastian between VNets"
  }
  security_rule {
    name                       = "Outbound-https-Internet"
    priority                   = 170
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Allow Https outbound to Internet"
  }
  ## Ingress Traffic from Azure Bastion:
  ## Azure Bastion will reach to the target VM over private IP.
  ## RDP/SSH ports (ports 3389/22 respectively, or custom port values if you are using the custom 
  ## port feature as a part of Standard SKU) need to be opened on the target VM side
  ##  over private IP. As a best practice, you can add the Azure Bastion Subnet IP address
  ##  range in this rule to allow only Bastion to be able to open these ports on the target VMs 
  ## in your target VM subnet.
  security_rule {
    name                       = "Outbound-AllowSshRdp-to-Vnet"
    priority                   = 180
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow SSH/RDP from Bastion to VNets"
  }

  ## Outbound: AzureAustraliaEast
  security_rule {
    name                       = "Allow-Azure"
    priority                   = 606
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
    description                = "Allow Azure Cloud"
  }

  ## Outbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Inbound as part of Zero Trust Networking"
  }

  ## Inbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Outound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Allow" ## needs to be "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Outbound as part of Zero Trust Networking"
  }

  tags = each.value.tags
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags.created]
  }
}

resource "azurerm_network_security_group" "linux" {
  for_each = azurerm_virtual_network.vnet

  name                = "nsg-${var.landing_zone_name}-${local.regions[each.value.location].short_name}-linux"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  ## ===========================================================================================================
  ## Outbound: Azure Instance Metadata Service endpoint
  security_rule {
    name                    = "Outbound-to-Azure-Metadata-Service-endpoint"
    priority                = 101
    direction               = "Outbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_port_range       = "*"
    destination_port_ranges = ["80", "443"]
    source_address_prefix   = "VirtualNetwork"
    ## Service Tag: "AzurePlatformIMDS" but can only be used on deny rule
    destination_address_prefix = "169.254.169.254"
    description                = "Allow access to internal Azure Instance Metadata Service (IMDS)"
  }
  ## Outbound: Azure DNS
  security_rule {
    name                    = "Outbound-to-Azure-DNS"
    priority                = 102
    direction               = "Outbound"
    access                  = "Allow"
    protocol                = "*"
    source_port_range       = "*"
    destination_port_ranges = ["53", "443"]
    source_address_prefix   = "VirtualNetwork"
    ## Service Tag: "AzurePlatformDNS"  but can only be used on deny rule
    destination_address_prefix = "168.63.129.16"
    description                = "Allow access to internal Azure DNS service (for lookups)"
  }
  ## Outbound: Any DNS
  security_rule {
    name                   = "Outbound-to-Any-DNS"
    priority               = 103
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "53"
    source_address_prefix  = "VirtualNetwork"
    ## Service Tag: "AzurePlatformDNS"  but can only be used on deny rule
    destination_address_prefix = "*"
    description                = "Allow access to any DNS service (for lookups/troubleshooting)"
  }
  ## ICMP (ping) - Inbound (VirtualNetwork)
  security_rule {
    name                       = "Inbound-ICMP-from-VNet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow pings between VNets"
  }
  ## ICMP (ping) - Outbound (VirtualNetwork)
  security_rule {
    name                       = "Outbound-ICMP-from-VNet"
    priority                   = 111
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow pings for connectivity checks/troubleshooting between VirtualNetwork"
  }
  ## ICMP (ping) - Outbound (Internet)
  security_rule {
    name                       = "Outbound-ICMP-to-Any"
    priority                   = 112
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Allow pings for connectivity checks/troubleshooting"
  }
  ## HTTPS - Outbound (VirtualNetworks)
  security_rule {
    name                       = "Outbound-AllowHttps-between-VirtualNetworks"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow HTTPS between VirtualNetworks (private endpoints)"
  }
  ## HTTPS - Outbound (Azure AD (Entra ID))
  security_rule {
    name                       = "Outbound-Allow-to-Entra-ID"
    priority                   = 122
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
    description                = "Allow Outbound access to Entra ID (AAD - Azure Active Directory) for logon amongst many others"
  }
  ## HTTPS - Outbound (Any)
  security_rule {
    name                       = "Outbound-Allow-Https-to-Any"
    priority                   = 123
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    description                = "Allow HTTPS to Any"
  }
  ## HTTPS - Inbound (any)
  security_rule {
    name                       = "Inbound-AllowHttps-from-any"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
    description                = "Inbound Allow HTTPS from any"
  }

  ## Linux: Time - Outbound
  security_rule {
    name                       = "Outbound-Time-to-Any"
    priority                   = 510
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "123"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    description                = "Outbound Allow NTP to any"
  }
  ## Linux: Syslog - Outbound (VirtualNetwork)
  security_rule {
    name                       = "Outbound-Syslog-to-VirtualNetwork"
    priority                   = 520
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["514", "1514"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Outbound Allow Syslog to VirtualNetwork"
  }
  ## Linux: Syslog - Outbound (any)
  security_rule {
    name                       = "Outbound-Syslog-to-Any"
    priority                   = 530
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["514", "1514"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Outbound Allow Syslog to any"
  }
  ## SysLog (UDP)
  security_rule {
    name                       = "Inbound-Syslog-UDP-from-Internet"
    priority                   = 540
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_port_ranges    = ["514", "1514"]
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Syslog inbound from any"
  }
  ## SysLog (TCP)
  security_rule {
    name                       = "Inbound-Syslog-TCP-from-Any"
    priority                   = 550
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["514", "1514", "6514"]
    description                = "Allow Syslog inbound from any"
  }
  ## Linux: NFS (Any/2049)
  security_rule {
    name                       = "Outbound-AllowNFS-VirtualNetwork"
    priority                   = 560
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["2049"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Outbound Allow NFS Internal VNets"
  }
  ## Linux: NFS (Any/111)
  security_rule {
    name                       = "Outbound-AllowNFSRPC-VirtualNetwork"
    priority                   = 620
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "111"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Outbound Allow NFS RPC Internal VNets"
  }
  security_rule {
    name                       = "Outbound-AllowNFS-Internet"
    priority                   = 630
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["2049"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Outbound Allow NFS to Internet"
  }
  ## Linux: NFS (Any/111)
  security_rule {
    name                       = "Outbound-AllowNFSRPC-Internet"
    priority                   = 640
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "111"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Outbound Allow NFS RPC to Internet"
  }

  ## Outbound: AzureAustraliaEast
  security_rule {
    name                       = "Allow-Azure-AustraliaEast"
    priority                   = 606
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiaeast"
    description                = "Allow Azure Cloud, but just Australia East region"
  }
  ## Outbound: AzureAustraliaSouthEast
  security_rule {
    name                       = "Allow-Azure-AustraliaSouthEast"
    priority                   = 607
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiasoutheast"
    description                = "Allow Azure Cloud, but just Australia Southeast region"
  }
  ## Outbound: AzureAustraliaCentral1
  security_rule {
    name                       = "Allow-Azure-AustraliaCentral1"
    priority                   = 608
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiacentral"
    description                = "Allow Azure Cloud, but just Australia Central1 region"
  }
  ## Outbound: AzureAustraliaCentral2
  security_rule {
    name                       = "Allow-Azure-AustraliaCentral2"
    priority                   = 609
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiacentral2"
    description                = "Allow Azure Cloud, but just Australia Central2 region"
  }
  ## Outbound: AzureSouthAsia
  security_rule {
    name                       = "Allow-Azure-SouthEastAsia"
    priority                   = 610
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.southeastasia"
    description                = "Allow Azure Cloud, but just South Asia (Singapore) for Static Web App (not hosted in Australian regions)"
  }

  ## Outbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Inbound as part of Zero Trust Networking"
  }

  ## Inbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Outound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Allow" ## needs to be "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Outbound as part of Zero Trust Networking"
  }

  tags = each.value.tags
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags.created]
  }
}

resource "azurerm_network_security_group" "windows" {
  for_each = azurerm_virtual_network.vnet

  name                = "nsg-${var.landing_zone_name}-${local.regions[each.value.location].short_name}-windows"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  ## ===========================================================================================================
  ## Outbound: Azure Instance Metadata Service endpoint
  security_rule {
    name                    = "Allow-Azure-Metadata-endpoint"
    priority                = 101
    direction               = "Outbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_port_range       = "*"
    destination_port_ranges = ["80", "443"]
    source_address_prefix   = "VirtualNetwork"
    ## Service Tag: "AzurePlatformIMDS" but can only be used on deny rule
    destination_address_prefix = "169.254.169.254"
    description                = "Allow access to internal Azure Instance Metadata Service (IMDS)"
  }
  ## Outbound: Azure DNS
  security_rule {
    name                    = "Allow-Azure-DNS"
    priority                = 102
    direction               = "Outbound"
    access                  = "Allow"
    protocol                = "*"
    source_port_range       = "*"
    destination_port_ranges = ["53", "443"]
    source_address_prefix   = "VirtualNetwork"
    ## Service Tag: "AzurePlatformDNS"  but can only be used on deny rule
    destination_address_prefix = "168.63.129.16"
    description                = "Allow access to internal Azure DNS service (for lookups)"
  }
  ## Outbound: Any DNS
  security_rule {
    name                   = "Allow-Outbound-to-Any-DNS"
    priority               = 103
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "53"
    source_address_prefix  = "VirtualNetwork"
    ## Service Tag: "AzurePlatformDNS"  but can only be used on deny rule
    destination_address_prefix = "*"
    description                = "Allow access to any DNS service (for lookups/troubleshooting)"
  }
  ## ICMP (ping) - Inbound (VirtualNetwork)
  security_rule {
    name                       = "Allow-Inbound-ICMP-from-VNets"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow pings for connectivity checks/troubleshooting between VirtualNetwork within Azure"
  }
  ## ICMP (ping) - Outbound (VirtualNetwork)
  security_rule {
    name                       = "Allow-Outbound-ICMP-from-VNets"
    priority                   = 111
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow pings for connectivity checks/troubleshooting between VirtualNetwork within Azure"
  }
  ## ICMP (ping) - Outbound (Internet)
  security_rule {
    name                       = "Allow-Outbound-ICMP-to-Any"
    priority                   = 112
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Allow outbound pings for connectivity checks/troubleshooting"
  }
  ## Inbound: Bastian (Developer SKU)
  security_rule {
    name                       = "Allow-Bastian"
    priority                   = 113
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Azure Bastian access to both SSH amd RDP"
  }
  ## Inbound: Bastian (other than Developer SKU)
  security_rule {
    name                       = "Allow-Bastian-Developer"
    priority                   = 114
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "168.63.129.16"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Azure Bastian Developer access to both SSH amd RDP"
  }
  ## HTTPS - Outbound (VirtualNetworks)
  security_rule {
    name                       = "Allow-Outbound-Https-between-VirtualNetworks"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow HTTPS between VirtualNetworks (private endpoints)"
  }
  ## HTTPS - Outbound (Azure)
  security_rule {
    name                       = "Allow-Outbound-Https-within-Azure"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
    description                = "Allow HTTPS to Azure Cloud (service endpoints) within Azure"
  }
  ## HTTPS - Outbound (Azure AD (Entra ID))
  security_rule {
    name                       = "Allow-Outbound-Entra-ID"
    priority                   = 300
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
    description                = "Allow Outbound access to Entra ID (AAD - Azure Active Directory) also needed for WindowsAdminCenter"
  }
  // Outbound HTTPS to WindowsAdminCenter
  security_rule {
    name                       = "Allow-Outbound-WindowsAdminCenter"
    priority                   = 400
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "WindowsAdminCenter"
    description                = "Allow Outbound access to the Windows Admin Centre service"
  }
  ## HTTPS - Outbound (Any)
  security_rule {
    name                       = "Allow-Outbound-Https-to-Any"
    priority                   = 500
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    description                = "Allow HTTPS to Any"
  }
  ## HTTPS - Inbound (any)
  security_rule {
    name                       = "Allow-Inbound-Https-from-Vnets"
    priority                   = 600
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Inbound Allow HTTPS from any"
  }
  ## SSH/RDP (intended to be only via bastian)
  security_rule {
    name                       = "Allow-Inbound-Https-from-Gateways"
    priority                   = 700
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow SSH from VirtualNetworks [so not from the Internet] (expected to be Bastian)"
  }
  ## SSH/RDP (intended to be only via bastian)
  security_rule {
    name                       = "Allow-Inbound-Https-from-NLB"
    priority                   = 800
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow RDP from VirtualNetworks [so not from the Internet] (expected to be Bastian)"
  }
  // Outbound: KMS azkms.core.windows.net and kms.core.windows.net
  security_rule {
    name                   = "Allow-Outbound-Azure-Windows-KMS"
    priority               = 900
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "1688"
    source_address_prefix  = "VirtualNetwork"
    ## Service Tag: "AzurePlatformLKM" but can only be used on deny rule
    // destination_address_prefixes = ["20.118.99.224", "40.83.235.53", "23.102.135.246", "azkms.core.windows.net", "kms.core.windows.net"]
    destination_address_prefixes = ["20.118.99.224", "40.83.235.53", "23.102.135.246"]
    description                  = "Allow Outbound to Azure KMS for Windows activation/licensing"
  }
  // Inbound HTTPS/6516 for WindowsAdminCenter
  security_rule {
    name                       = "Allow-Inbound-WindowsAdminCenter"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6516"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow-Inbound-AdminCenter-from-Any (including Internet)"
  }
  ## WinRM (for Packer and others)
  security_rule {
    name                       = "Inbound-Allow-WinRM-between-vNETs"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5985-5986"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Inbound WinRM from VNets (for Packer and others)"
  }
  ## Outbound: Entra ID Domain Services
  security_rule {
    name                       = "Outbound-Allow-Domain-Services"
    priority                   = 1200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "88", "443", "468", "3268-3269"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectoryDomainServices"
    description                = "Allow Outbound Active Directory Domain Services"
  }
  ## Outbound: Windows 365, AVD, Devbox (UDP)
  security_rule {
    name                       = "Outbound-Allow-TURN-Audio-MSTeams"
    priority                   = 1300
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "3478"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "20.202.0.0/16"
    description                = "Outbound TURN for Microsoft Teams Audio"
  }
  ## Outbound: Kerberos/SMB storage
  ## TCP Port 88: Used for Kerberos authentication.
  ## TCP Port 135: Required for RPC (Remote Procedure Call) services.
  ## TCP Port 139: Used for NetBIOS session service.
  ## TCP Port 445: Necessary for SMB (Server Message Block) protocol.
  ## TCP Port 464: Used for Kerberos password changes.
  ## TCP Port 3268 and 3269: Required for Global Catalog services.
  ## Ephemeral Ports: TCP and UDP ports 49152-65535 for dynamic port allocation
  security_rule {
    name                       = "Outbound-SMB-Kerberos-VirtualNetwork"
    priority                   = 1400
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["88", "135", "139", "445", "464", "3268-3269"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Outbound Windows Storage access (private endpoints)"
  }
  security_rule {
    name                       = "Outbound-SMB-Kerberos-Azure"
    priority                   = 1500
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["88", "135", "139", "445", "464", "3268-3269"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
    description                = "Outbound Windows Storage access (private endpoints)"
  }
  security_rule {
    name                       = "Deny-SMB-Kerberos-Internet"
    priority                   = 1600
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["88", "135", "139", "445", "464", "3268-3269"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Deny Outbound Kerberos Storage access (over Internet)"
  }
  ## Ephemeral Ports: TCP and UDP ports 49152-65535 for dynamic port allocation
  security_rule {
    name                       = "Outbound-SMB-Storage-Ephemeral-VirtalNetwork"
    priority                   = 1700
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["49152-65535"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Outbound SMB Storage access"
  }
  security_rule {
    name                       = "Outbound-SMB-Storage-Ephemeral-Azure"
    priority                   = 1800
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["49152-65535"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
    description                = "Outbound SMB Storage access"
  }
  security_rule {
    name                       = "Outbound-SMB-Storage-Ephemeral-Internet"
    priority                   = 1900
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["49152-65535"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Outbound Windows Storage access"
  }

  // Outbound: Windows 365, AVD, Devbox (UDP)
  // https://learn.microsoft.com/en-us/windows-365/enterprise/azure-firewall-windows-365
  // global.azure-devices-provisioning.net
  // hm-iot-in-prod-preu01.azure-devices.net
  // hm-iot-in-prod-prap01.azure-devices.net
  // hm-iot-in-prod-prna01.azure-devices.net
  // hm-iot-in-prod-prau01.azure-devices.net
  // hm-iot-in-prod-prna02.azure-devices.net
  // hm-iot-in-2-prod-prna01.azure-devices.net
  // hm-iot-in-3-prod-prna01.azure-devices.net
  // hm-iot-in-2-prod-preu01.azure-devices.net
  // hm-iot-in-3-prod-preu01.azure-devices.net
  // hm-iot-in-4-prod-prna01.azure-devices.net
  security_rule {
    name                       = "Outbound-Allow-Registrations-for-Intune"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "5671"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Outbound UDP-3478 to Any for Windows 365"
  }

  ## Outbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Inbound as part of Zero Trust Networking"
  }

  ## Inbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Outound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Allow" ## needs to be "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Outbound as part of Zero Trust Networking"
  }

  tags = each.value.tags
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags.created]
  }
}

resource "azurerm_network_security_group" "unifi" {
  for_each = azurerm_virtual_network.vnet

  name                = "nsg-${var.landing_zone_name}-${local.regions[each.value.location].short_name}-unifi-controller"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  ## ===========================================================================================================
  ## Outbound: Azure Instance Metadata Service endpoint
  security_rule {
    name                    = "Allow-Azure-Metadata-endpoint"
    priority                = 111
    direction               = "Outbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_port_range       = "*"
    destination_port_ranges = ["80", "443"]
    source_address_prefix   = "VirtualNetwork"
    ## Service Tag: "AzurePlatformIMDS" but can only be used on deny rule
    destination_address_prefix = "169.254.169.254"
    description                = "Allow access to Azure Instance Metadata Service (IMDS)"
  }
  ## Inbound: Bastian (Developer SKU)
  security_rule {
    name                       = "Allow-Bastian"
    priority                   = 112
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Azure Bastian access to SSH amd RDP (All SKUs, except Developer)"
  }
  ## Inbound: Bastian (other than Developer SKU)
  security_rule {
    name                       = "Allow-Bastian-Developer"
    priority                   = 113
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "168.63.129.16" ## this is the IP for the Bastian service
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Azure Bastian Developer SKU access to SSH amd RDP"
  }
  ## Outbound: Azure DNS
  security_rule {
    name                    = "Allow-Azure-DNS"
    priority                = 114
    direction               = "Outbound"
    access                  = "Allow"
    protocol                = "*"
    source_port_range       = "*"
    destination_port_ranges = ["53", "443"]
    source_address_prefix   = "VirtualNetwork"
    ## Service Tag: "AzurePlatformDNS"  but can only be used on deny rule
    destination_address_prefix = "168.63.129.16"
    description                = "Allow access to internal Azure DNS service (for lookups)"
  }
  ## Outbound: Any DNS
  security_rule {
    name                       = "Allow-Internet-DNS"
    priority                   = 115
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Allow access to any (Internet) DNS service (for lookups/troubleshooting)"
  }
  ## Unifi: Allow syslog
  security_rule {
    name                       = "Allow-Syslog-to-Azure"
    priority                   = 116
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["5514", "6514", "8514", "10514"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
    description                = "Used for Syslog monitoring (receiver needs to be hosted in Azure)"
  }
  ## Unifi: Used for device and application communication.
  security_rule {
    name                       = "Allow-Unifi-Comms-from-Internet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "8443", "8080", "8880", "8843"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
    description                = "Used for device and application communication. TCP/8080 critical for Unifi devices to talk to controller."
  }
  ## Used for UniFi mobile speed test.
  security_rule {
    name                       = "Allow-Unifi-Speed-Test"
    priority                   = 121
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["6789"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
    description                = "Used for UniFi mobile speed test."
  }
  ## Uniif: Used by AP-EDU broadcasting.
  security_rule {
    name                       = "Allow-Unifi-EDU-Broadcasting-from-Internet"
    priority                   = 122
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "5656-5699"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
    description                = "Used by AP-EDU broadcasting."
  }
  ## HTTPS - Outbound (Any)
  security_rule {
    name                       = "Allow-Unifi-Device-Discovery-from-Internet"
    priority                   = 123
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "10001"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Unifi Device Discovery"
  }
  ## HTTPS - Inbound (VirtualNetwork)
  security_rule {
    name                       = "Allow-Https-from-any-VNet"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Inbound Allow HTTPS from any"
  }
  ## Outbound: Entra ID Domain Services
  security_rule {
    name                       = "Allow-Entra-ID"
    priority                   = 604
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "5000", "5001", "8080", "8443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
    description                = "Allow Entra ID (AAD) access"
  }
  ## Outbound: AzureAdvancedThreatProtection
  security_rule {
    name                       = "Allow-MSFT-Defender-Identity"
    priority                   = 605
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureAdvancedThreatProtection"
    description                = "Allow Entra ID (AAD) access"
  }
  ## Outbound: AzureAustraliaEast
  security_rule {
    name                       = "Allow-Azure-AustraliaEast"
    priority                   = 606
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiaeast"
    description                = "Allow Azure Cloud, but just Australia East region"
  }
  ## Outbound: AzureAustraliaSouthEast
  security_rule {
    name                       = "Allow-Azure-AustraliaSouthEast"
    priority                   = 607
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiasoutheast"
    description                = "Allow Azure Cloud, but just Australia Southeast region"
  }
  ## Outbound: AzureAustraliaCentral1
  security_rule {
    name                       = "Allow-Azure-AustraliaCentral1"
    priority                   = 608
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiacentral"
    description                = "Allow Azure Cloud, but just Australia Central1 region"
  }
  ## Outbound: AzureAustraliaCentral2
  security_rule {
    name                       = "Allow-Azure-AustraliaCentral2"
    priority                   = 609
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.australiacentral2"
    description                = "Allow Azure Cloud, but just Australia Central2 region"
  }
  ## Outbound: AzureSouthAsia
  security_rule {
    name                       = "Allow-Azure-SouthEastAsia"
    priority                   = 610
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud.southeastasia"
    description                = "Allow Azure Cloud, but just South Asia (Singapore) for Static Web App (not hosted in Australian regions)"
  }
  ## Inbound: AzureLoadBalancer
  security_rule {
    name                       = "Allow-Azure-Load-Balancer"
    priority                   = 707
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Azure Load Balancer"
  }
  ## Inbound: AzureLoadBalancer
  security_rule {
    name                       = "Allow-Azure-Gateway"
    priority                   = 708
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow Azure Gateways (VPN & App Gateway)"
  }
  ## Inbound: Security Products
  security_rule {
    name                       = "Allow-Azure-Defender-Sentinel"
    priority                   = 709
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Scuba"
    destination_address_prefix = "VirtualNetwork"
    description                = "Data connectors for Microsoft security products (Sentinel, Defender, etc.)."
  }

  ## Outbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Inbound as part of Zero Trust Networking"
  }

  ## Inbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Outound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Allow" ## needs to be "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Outbound as part of Zero Trust Networking"
  }

  tags = each.value.tags
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags.created]
  }
}

resource "azurerm_network_security_group" "dns" {
  for_each = azurerm_virtual_network.vnet

  name                = "nsg-${var.landing_zone_name}-${local.regions[each.value.location].short_name}-dns"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  ## Outbound: Azure Instance Metadata Service endpoint
  security_rule {
    name                       = "Allow-Azure-Metadata-Service-endpoint"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "169.254.169.254"
    description                = "Allow outbound access to Azure Instance Metadata Service (IMDS) so things like managed identity and packet capture will work"
  }
  ## Inbound: DNS (VirtualNetwork)
  security_rule {
    name                       = "Allow-DNS-from-VirtualNetwork"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["53", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow inbound access to DNS from Virtual Networks"
  }
  ## Inbound: DNS (Internet)
  security_rule {
    name                       = "Deny-DNS-from-Internet"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["53", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow inbound access to DNS from Internet"
  }
  ## Outbound: DNS (VirtualNetwork)
  security_rule {
    name                       = "Allow-Azure-DNS"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["53", "443", "8037"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "168.63.129.16"
    description                = "Outbound to Azure DNS including packet capture over TCP 8037"
  }
  ## Outbound: DNS (Internet)
  security_rule {
    name                       = "Allow-External-DNS-Lookups"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["53"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    description                = "Outbound to any DNS including Internet - for troubleshooting"
  }

  ## Outbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Inbound as part of Zero Trust Networking"
  }

  ## Inbound: Deny All
  security_rule {
    name                       = "Deny-Anything-Else-Outound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Allow" ## needs to be "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny ALL Outbound as part of Zero Trust Networking"
  }

  tags = each.value.tags
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags.created]
  }
}

