


locals {
  ## Options: Developer (free), Basic ($), Standard ($$$), Premium ($$$$$)
  bastion_sku = var.sku_name == "free" ? "Developer" : (var.sku_name == "premium" || var.sku_name == "isolated") ? "Premium" : "Basic"
}

module "bastion_public_ip" {
  source           = "Azure/avm-res-network-publicipaddress/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = local.regions[var.location_key].location
  edge_zone           = local.regions[var.location_key].edge_zone
  zones               = local.regions[var.location_key].zones

  allocation_method = "Static"
  sku               = "Standard"
  sku_tier          = local.bastion_sku == "Premium" ? "Global" : "Regional"
  domain_name_label = module.naming[each.key].public_ip.name_unique
  #domain_name_label_scope = "TenantReuse"

  #ddos_protection_mode = var.ddos_protection_mode
  #ddos_protection_plan_id = var.ddos_protection_plan_id
  tags = azurerm_resource_group.this.tags
}
## value = module.bastion_public_ip.public_ip_id  # Resource ID
## value = module.bastion_public_ip.public_ip_id  # Public IP Address resource ID

resource "azurerm_monitor_diagnostic_setting" "bastion_public_ip1" {
  for_each = local.bastion_sku == "Developer" ? {} : module.bastion_public_ip

  name                       = "Logs-${each.value.name}-to-Azure-Monitor"
  target_resource_id         = each.value.resource.id
  log_analytics_workspace_id = module.log_analytics_workspace[var.location_key].resource.id

  enabled_log {
    category_group = "allLogs"
  }
}

module "azure_bastion" {
  source           = "Azure/avm-res-network-bastionhost/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  name                = module.naming.bastion_host.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  copy_paste_enabled  = true

  sku = local.bastion_sku

  ip_configuration = local.bastion_sku == "Developer" ? {
    name                 = module.naming.network_interface.name_unique
    subnet_id            = module.virutal_network.subnets.bastion.resource_id
    public_ip_address_id = module.bastion_public_ip.resource.id
  } : null
  virtual_network_id = local.bastion_sku == "Developer" ? module.virutal_network.resource.id : null

  // Standard SKU (or higher) support only
  file_copy_enabled         = local.bastion_sku == "Standard" || local.bastion_sku == "Premium" ? true : false
  shareable_link_enabled    = local.bastion_sku == "Standard" || local.bastion_sku == "Premium" ? true : false
  tunneling_enabled         = local.bastion_sku == "Standard" || local.bastion_sku == "Premium" ? true : false
  scale_units               = 2
  ip_connect_enabled        = local.bastion_sku == "Standard" || local.bastion_sku == "Premium" ? true : false
  kerberos_enabled          = local.bastion_sku == "Standard" || local.bastion_sku == "Premium" ? true : false
  session_recording_enabled = local.bastion_sku == "Premium" ? true : false
  zones                     = local.bastion_sku == "Developer" ? null : local.regions[each.key].zones

  #  timeouts = {
  #    create = "90m"
  #  }
  lock = (local.contains_real_data) ? {
    kind = local.lock_kind
    name = local.iac_message
  } : null
  tags = local.tags_default
}


resource "azurerm_monitor_diagnostic_setting" "bastion1" {
  for_each = local.bastion_sku == "Developer" ? {} : azurerm_bastion_host.bastion

  name = "Metrics-${each.value.name}-to-Azure-Monitor"

  target_resource_id = each.value.id

  log_analytics_workspace_id = module.log_analytics_workspace[var.location_key].resource.id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "bastion2" {
  for_each = local.bastion_sku == "Developer" ? {} : azurerm_bastion_host.bastion

  name = "Logs-${each.value.name}-to-Azure-Monitor"

  target_resource_id = each.value.id

  log_analytics_workspace_id = module.log_analytics_workspace[var.location_key].resource.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_log {
    category_group = "audit"
  }
}

