module "log_analytics_workspace" {
  source           = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  name                                      = each.value.log_analytics_workspace.name_unique
  location                                  = local.regions[var.location_key].location
  resource_group_name                       = data.azurerm_resource_group.this.name
  log_analytics_workspace_retention_in_days = var.sku_name == "free" ? 3 : var.sku_name == "basic" ? 7 : var.sku_name == "standard" ? 14 : var.sku_name == "premium" ? 300 : 300
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_identity = {
    type = "UserAssigned"
    identity_ids = [
      module.user-assigned-identity-landing_zone.resource_id
    ]
  }
  log_analytics_workspace_internet_ingestion_enabled = local.contains_real_data == true ? false : true
  log_analytics_workspace_internet_query_enabled     = local.contains_real_data == true ? false : true

  lock = (local.contains_real_data) ? {
    kind = "CanNotDelete"
    name = local.iac_message
  } : null
  tags = local.tags_default
}
module "log_analytics_workspace" {
  source           = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  name                                      = each.value.log_analytics_workspace.name_unique
  location                                  = local.regions[var.location_key].location
  resource_group_name                       = data.azurerm_resource_group.this.name
  log_analytics_workspace_retention_in_days = var.sku_name == "free" ? 3 : var.sku_name == "basic" ? 7 : var.sku_name == "standard" ? 14 : var.sku_name == "premium" ? 300 : 300
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_identity = {
    type = "UserAssigned"
    identity_ids = [
      module.user-assigned-identity-landing_zone.resource_id
    ]
  }
  log_analytics_workspace_internet_ingestion_enabled = local.contains_real_data == true ? false : true
  log_analytics_workspace_internet_query_enabled     = local.contains_real_data == true ? false : true

  role_assignments = {
    log_analytics_contributor = {
      principal_id               = module.user_assigned_identity.resource.principal_id
      role_definition_id_or_name = "Log Analytics Contributor"
    }
    log_analytics_reader = {
      principal_id               = var.entra_group_pag_id
      role_definition_id_or_name = "Log Analytics Reader"
    }
    monitoring_reader = {
      principal_id               = var.entra_group_pag_id
      role_definition_id_or_name = "Monitoring Reader"
      scope_resource_id          = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
    }
  }

  lock = (local.contains_real_data) ? {
    kind = "CanNotDelete"
    name = local.iac_message
  } : null
  tags = local.tags_default
}

resource "azurerm_application_insights" "web" {
  application_type    = "web"
  name                = "web-${module.log_analytics_workspace.resource.name}"
  resource_group_name = module.log_analytics_workspace[var.location_key].resource.resource_group_name
  location            = module.log_analytics_workspace[var.location_key].resource.location
  workspace_id        = module.log_analytics_workspace[var.location_key].resource.resource_id
  tags                = local.tags_default
  lifecycle {
    ignore_changes = [tags.created]
  }
}
resource "azurerm_application_insights_snapshot_debugger" "web" {
  application_insights_id = azurerm_application_insights.shared_log_analytics.id
  enabled                 = true
}
resource "azurerm_role_assignment" "application_insights_snapshot_debugger" {
  principal_id         = var.entra_group_pag_id
  scope                = azurerm_application_insights.web.id
  role_definition_name = "Application Insights Snapshot Debugger"
}
resource "azurerm_role_assignment" "application_insights_contributor1" {
  principal_id         = module.user-assigned-identity-landing_zone.resource.principal_id
  scope                = azurerm_application_insights.web.id
  role_definition_name = "Application Insights Contributor"
}
resource "azurerm_role_assignment" "application_insights_contributor2" {
  principal_id         = var.entra_group_pag_id
  scope                = azurerm_application_insights.web.id
  role_definition_name = "Application Insights Contributor"
}


resource "azurerm_monitor_workspace" "grafana" {
  name = module.log_analytics_workspace.resource.name

  resource_group_name           = module.log_analytics_workspace[var.location_key].resource.resource_group_name
  location                      = module.log_analytics_workspace[var.location_key].resource.location
  public_network_access_enabled = local.contains_real_data == true ? false : true

  ## default_data_collection_endpoint_id - The ID of the managed default Data Collection Endpoint created with the Azure Monitor Workspace.
  ## default_data_collection_rule_id - The ID of the managed default Data Collection Rule created with the Azure Monitor Workspace.

  tags = module.log_analytics_workspace.resource.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}
resource "azurerm_role_assignment" "grafana_contributor" {
  principal_id         = module.user-assigned-identity-landing_zone.resource.principal_id
  scope                = azurerm_monitor_workspace.grafana.id
  role_definition_name = "Azure Managed Grafana Workspace Contributor"
}
resource "azurerm_role_assignment" "grafana_viewer" {
  principal_id         = module.user-assigned-identity-landing_zone.resource.principal_id
  scope                = azurerm_monitor_workspace.grafana.id
  role_definition_name = "Grafana Viewer"
}


/*
// Grafana dasboard
resource "azurerm_dashboard_grafana" "grafana" {
  for_each = azurerm_resource_group.grafana

  name                              = "grafana"
  resource_group_name               = each.value.name
  location                          = each.value.location
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = false
  grafana_major_version = "10"
  
  // Possible values are Standard and Essential 
  sku = "Essential"
  
  identity {
    type = "SystemAssigned"
  }

//  smtp {
//    enabled = false
//    host = "test.email.net:587"
//    user = "xxxxx"
//    password = "yyyyy"
    // Possible values are OpportunisticStartTLS, NoStartTLS, MandatoryStartTLS.
//    start_tls_policy = "MandatoryStartTLS"
//    from_address = "dsdaa@sssaas.com"
//    verification_skip_enabled = true
//  }

  azure_monitor_workspace_integrations {
    resource_id = data.azurerm_log_analytics_workspace.shared_log_analytics[each.key].id
  }
  
  zone_redundancy_enabled = false
  tags = each.value.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}
*/


