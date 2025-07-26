# This is the module call
module "keyvault" {
  for_each = module.naming

  source           = "Azure/avm-res-keyvault-vault/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  name                = module.naming-landing-zone.key_vault.name_unique
  resource_group_name = data.azurerm_resource_group.this.name
  location            = local.regions[var.location_key].location

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  sku_name                        = "standard"
  network_acls = {
    bypass                     = local.contains_real_data ? "None" : "AzureServices"
    default_action             = local.contains_real_data ? "Allow" : "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
  public_network_access_enabled = local.contains_real_data ? false : true
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    customer_managed_key = {
      role_definition_id_or_name = "Key Vault Crypto Officer"
      principal_id               = azurerm_user_assigned_identity.this.principal_id
    }
    secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = azurerm_user_assigned_identity.this.principal_id
    }
    certificate_user = {
      role_definition_id_or_name = "Key Vault Certificate User"
      principal_id               = azurerm_user_assigned_identity.this.principal_id
    }
    reader1 = {
      role_definition_id_or_name = "Key Vault Reader"
      principal_id               = azurerm_user_assigned_identity.this.principal_id
    }
    reader2 = {
      role_definition_id_or_name = "Key Vault Reader"
      principal_id               = var.entra_group_pag_id
    }
  }
  lock = (local.contains_real_data) ? {
    kind = local.lock_kind
    name = local.iac_message
  } : null
  tags = local.tags_default
}

