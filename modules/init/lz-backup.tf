locals {
  ## PII: 30 days, Non-PII 7 days - change as required
  backup_retention = local.contains_real_data ? "P30D" : "P7D"
}


## only cheapest options for the moment
resource "azurerm_data_protection_backup_vault" "this" {
  name                         = "${var.landing_zone_name}-backup-vault"
  resource_group_name          = data.azurerm_resource_group.this.name
  location                     = data.azurerm_resource_group.this.location
  datastore_type               = "VaultStore"                                                   ## Possible values are ArchiveStore, OperationalStore, and VaultStore
  cross_region_restore_enabled = true                                                           // can only be ture if redunancy is GeoRedundant
  redundancy                   = local.contains_real_data ? "GeoRedundant" : "LocallyRedundant" ## Possible values are GeoRedundant, LocallyRedundant and ZoneRedundant
  immutability                 = local.contains_real_data ? "Locked" : "Disabled"               ## Possible values are: "Disabled", "Locked", "Unlocked".

  identity {
    type = "SystemAssigned"
  }
  tags = local.tags_default
  lifecycle {
    ignore_changes = [
      tags.created,
    ]
  }
}
resource "azurerm_role_assignment" "vault_storage" {
  scope                = data.azurerm_client_config.current.subscription_id
  role_definition_name = "Storage Account Backup Contributor"
  principal_id         = azurerm_data_protection_backup_vault.this.identity[0].principal_id
}

resource "azurerm_recovery_services_vault" "vault" {
  name                = "${var.landing_zone_name}-recovery-vault"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  sku                 = "Standard"
  soft_delete_enabled = true
}
resource "azurerm_data_protection_resource_guard" "vault" {
  name                = "${azurerm_recovery_services_vault.vault.name}-resourceguard"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
}
resource "azurerm_recovery_services_vault_resource_guard_association" "vault" {
  vault_id          = azurerm_recovery_services_vault.vault.id
  resource_guard_id = azurerm_data_protection_resource_guard.value.id
}

resource "azurerm_data_protection_backup_policy_blob_storage" "blob" {
  name                                   = "blob-storage-backup-policy"
  vault_id                               = azurerm_data_protection_backup_vault.this.id
  operational_default_retention_duration = local.backup_retention
}

/*
resource "azurerm_data_protection_backup_instance_blob_storage" "blob" {
  name               = "example-backup-instance"
  vault_id           = azurerm_data_protection_backup_vault.this.id
  location           = azurerm_data_protection_backup_vault.this.location
  storage_account_id = azurerm_storage_account.example.id
  backup_policy_id   = azurerm_data_protection_backup_policy_blob_storage.blob.id

  depends_on = [azurerm_role_assignment.vault_storage]
}
*/

resource "azurerm_backup_policy_file_share" "short_retention" { ## 7 days
  name                = "{var.landing_zone_name}-file-share-backup-SHORT-retention-policy"
  resource_group_name = data.azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  timezone            = local.regions[var.location_key].timezone

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_policy_file_share" "long_retention" { ## 7 Years
  name                = "{var.landing_zone_name}-file-share-backup-LONG-retention-policy"
  resource_group_name = data.azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  timezone            = local.regions[var.location_key].timezone

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 7
    weekdays = ["Sunday", "Wednesday", "Friday", "Saturday"]
  }

  retention_monthly {
    count    = 7
    weekdays = ["Sunday", "Wednesday"]
    weeks    = ["First", "Last"]
  }

  retention_yearly {
    count    = 7
    weekdays = ["Sunday"]
    weeks    = ["Last"]
    months   = ["January"]
  }
}