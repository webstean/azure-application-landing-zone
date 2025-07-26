
## info: https://learn.microsoft.com/en-us/azure/communication-services/overview
## No AVM module yet

// the comms service is a global service
resource "azurerm_communication_service" "comms" {

  ##name = module.naming-application.app_configuration[each.key].name
  name = "${lower(var.landing_zone_name)}-${local.regions[each.key].short_name}-comms"

  resource_group_name = data.azurerm_resource_group.this.name
  data_location       = local.regions[var.location_key].data_location

  ## not supported 
  //  identity {
  //    type = "UserAssigned"
  //    identity_ids = [azurerm_user_assigned_identity.comms[each.key].id]
  //  }

  tags = local.tags_default
  lifecycle {
    ignore_changes = [tags.created]
  }
  timeouts {
    create = "60m"
    delete = "60m"
  }
}

resource "azapi_update_resource" "comms-identity" {

  type        = "Microsoft.Communication/communicationServices@2024-09-01-preview"
  resource_id = azurerm_communication_service.comms.id
  body = {
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = [
        module.user-assigned-identity-landing_zone.resource.id
      ]
    }
  }
}

resource "azurerm_email_communication_service" "comms" {
  name                = "${azurerm_communication_service.comms.name}-email01"
  resource_group_name = data.azurerm_resource_group.this.name
  data_location       = local.regions[var.location_key].data_location
  tags                = each.value.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}

resource "azurerm_email_communication_service_domain" "comms" {
  name                             = "AzureManagedDomain"
  email_service_id                 = azurerm_communication_service.comms.id
  domain_management                = "AzureManaged"
  user_engagement_tracking_enabled = true
  tags                             = each.value.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}

resource "azurerm_communication_service_email_domain_association" "comms" {
  for_each = azurerm_communication_service.comms

  communication_service_id = each.value.id
  email_service_domain_id  = azurerm_email_communication_service_domain.comms.id
}

/*
resource "azurerm_email_communication_service_domain_sender_username" "comms" {
  for_each = azurerm_communication_service.comms

  ## default is "DoNotReply"
  name                    = "noreply-terraform" ## "${data.azuread_domains.default.domains[0].domain_name}"
  email_service_domain_id = azurerm_email_communication_service_domain.comms[each.key].id
}
*/

resource "azurerm_monitor_diagnostic_setting" "comms1" {
  for_each = azurerm_communication_service.comms

  name = "Logs-${each.value.name}-to-Azure-Monitor"

  target_resource_id = each.value.id

  log_analytics_workspace_id = module.log_analytics_workspace.resource.id
  enabled_log {
    category_group = "allLogs"
  }
}
resource "azurerm_monitor_diagnostic_setting" "comms2" {
  for_each = azurerm_communication_service.comms

  name = "Metrics-${each.value.name}-to-Azure-Monitor"

  target_resource_id = each.value.id

  log_analytics_workspace_id = module.log_analytics_workspace.resource.id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_key_vault_secret" "primary-connection" {
  for_each = azurerm_communication_service.comms

  key_vault_id = module.keyvault.resource.id
  name         = "COMMS-PRIMARY-CONNECTION-STRING"
  value        = azurerm_communication_service.comms.primary_connection_string
}

resource "azurerm_key_vault_secret" "primary-key" {
  key_vault_id = module.keyvault.resource.id
  name         = "COMMS-PRIMARY-KEY"
  value        = azurerm_communication_service.comms.primary_key
}

resource "azurerm_key_vault_secret" "secondary-connection" {
  for_each = azurerm_communication_service.comms

  key_vault_id = module.keyvault.resource.id

  name  = "COMMS-SECONDARY-CONNECTION-STRING"
  value = each.value.secondary_connection_string
}

resource "azurerm_key_vault_secret" "secondary-key" {
  for_each = azurerm_communication_service.comms

  key_vault_id = module.keyvault.resource.id

  name  = "COMMS-SECONDARY-KEY"
  value = azurerm_communication_service.comms.secondary_key
}

resource "azurerm_key_vault_key" "comms_app_configuration" {
  for_each = (var.data_pii == "yes" || var.data_phi == "yes") ? module.keyvault : {}

  name         = "comms-appconfiguration-encryption-key-${each.value.name}"
  key_vault_id = each.value.resource.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
}

