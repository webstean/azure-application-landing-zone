

locals {
  privatednszones = {
    # Azure core services
    #    "automation"            = "privatelink.azure-automation.net"
    "sql" = "privatelink.database.windows.net"
    #    "synapse_sql"           = "privatelink.sql.azuresynapse.net"
    #    "synapse_dev"           = "privatelink.dev.azuresynapse.net"
    #    "synapse"               = "privatelink.azuresynapse.net"

    # Storage services
    "storage_blob"  = "privatelink.blob.core.windows.net"
    "storage_dfs"   = "privatelink.dfs.core.windows.net"
    "storage_file"  = "privatelink.file.core.windows.net"
    "storage_queue" = "privatelink.queue.core.windows.net"
    "storage_table" = "privatelink.table.core.windows.net"
    "storage_web"   = "privatelink.web.core.windows.net"

    # Cosmos DB services
    #    "cosmos_sql"            = "privatelink.documents.azure.com"
    #    "cosmos_mongo"          = "privatelink.mongo.cosmos.azure.com"
    #    "cosmos_cassandra"      = "privatelink.cassandra.cosmos.azure.com"
    #    "cosmos_gremlin"        = "privatelink.gremlin.cosmos.azure.com"
    #    "cosmos_table"          = "privatelink.table.cosmos.azure.com"

    # Other Azure services
    #    "batch"                 = "privatelink.batch.azure.com"
    #    "postgres"              = "privatelink.postgres.database.azure.com"
    #    "mysql"                 = "privatelink.mysql.database.azure.com"
    #    "mariadb"               = "privatelink.mariadb.database.azure.com"
    "keyvault" = "privatelink.vaultcore.azure.net"
    #    "hsm"                   = "privatelink.managedhsm.azure.net"
    #    "search"                = "privatelink.search.windows.net"
    "app_config" = "privatelink.azconfig.io"
    #    "site_recovery"         = "privatelink.siterecovery.windowsazure.com"
    #    "service_bus"           = "privatelink.servicebus.windows.net"
    #    "iot_hub"               = "privatelink.azure-devices.net"
    #    "dps"                   = "privatelink.azure-devices-provisioning.net"
    #    "event_grid"            = "privatelink.eventgrid.azure.net"
    #    "app_service"           = "privatelink.azurewebsites.net"
    #    "app_service_scm"       = "scm.privatelink.azurewebsites.net"
    #    "ml_api"                = "privatelink.api.azureml.msprivatelink.notebooks.azure.net"
    #    "signalr"               = "privatelink.service.signalr.net"
    "monitor"           = "privatelink.monitor.azure.com"
    "log_analytics"     = "privatelink.oms.opinsights.azure.com"
    "log_analytics_ods" = "privatelink.ods.opinsights.azure.com"
    #    "automation_agent"      = "privatelink.agentsvc.azure-automation.net"
    "app_insights" = "privatelink.applicationinsights.azure.com"
    #    "cognitive"             = "privatelink.cognitiveservices.azure.com"
    #    "openai"                = "privatelink.openai.azure.com"
    "datafactory"        = "privatelink.datafactory.azure.net"
    "datafactory_portal" = "privatelink.adf.azure.com"
    #    "redis"                 = "privatelink.redis.cache.windows.net"
    #    "redis_enterprise"      = "privatelink.redisenterprise.cache.azure.net"
    #    "purview"               = "privatelink.purview.azure.com"
    #    "purview_studio"        = "privatelink.purviewstudio.azure.com"
    #    "digital_twins"         = "privatelink.digitaltwins.azure.net"
    #    "hdinsight"             = "privatelink.azurehdinsight.net"
    #    "arc_his"               = "privatelink.his.arc.azure.com"
    #    "guest_config"          = "privatelink.guestconfiguration.azure.com"
    #    "k8s_config"            = "privatelink.kubernetesconfiguration.azure.com"
    #    "media"                 = "privatelink.media.azure.net"
    #    "migration"             = "privatelink.prod.migration.windowsazure.com"
    #    "api_management"        = "privatelink.azure-api.net"
    #    "api_dev_portal"        = "privatelink.developer.azure-api.net"
    #    "analysis"              = "privatelink.analysis.windows.net"
    #    "powerbi"               = "privatelink.pbidedicated.windows.net"
    #    "powerquery"            = "privatelink.tip1.powerquery.microsoft.com"
    #    "bot_direct"            = "privatelink.directline.botframework.com"
    #    "bot_token"             = "privatelink.token.botframework.com"
    #    "healthcare_workspace"  = "privatelink.workspace.azurehealthcareapis.com"
    #    "healthcare_fhir"       = "privatelink.fhir.azurehealthcareapis.com"
    #    "healthcare_dicom"      = "privatelink.dicom.azurehealthcareapis.com"
    #    "databricks"            = "privatelink.azuredatabricks.net"
  }
}

## Storage service	        Target sub-resource	Zone name
## Blob service	            blob	  privatelink.blob.core.windows.net
## Data Lake Storage Gen2	  dfs	    privatelink.dfs.core.windows.net
## File service	            file	  privatelink.file.core.windows.net
## Queue service	          queue	  privatelink.queue.core.windows.net
## Table service	          table	  privatelink.table.core.windows.net
## Static Websites	        web	    privatelink.web.core.windows.net

resource "azurerm_private_dns_zone" "privatelink-dns1" {
  for_each = { for k, v in local.privatednszones : k => v if var.private_endpoints_always_deployed == true }

  name                = lower(each.value)
  resource_group_name = data.azurerm_resource_group.this.name

  soa_record {
    email = "hostmaster.${data.azuread_domains.admin.domains[0].domain_name}"
    ttl   = 3600
    tags  = local.dns_tags_private
  }
  tags = azurerm_resource_group.this.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}

## region specific DNS privatelink zones
resource "azurerm_private_dns_zone" "privatelink-regions-dns1" {
  for_each = { for k, v in local.regions : k => v if var.private_endpoints_always_deployed == true }

  name                = format("%s.%s.%s", "privatelink", each.value.location, "backup.windowsazure.com")
  resource_group_name = data.azurerm_resource_group.this.name
  soa_record {
    email = "hostmaster.${data.azuread_domains.admin.domains[0].domain_name}"
    ttl   = 3600
    tags  = local.dns_tags_private
  }
  tags = azurerm_resource_group.this.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}

resource "azurerm_private_dns_zone" "privatelink-region-dns2" {
  for_each = { for k, v in local.regions : k => v if var.private_endpoints_always_deployed == true }

  name                = format("%s%s.%s", "privatelink.azurecr.io", each.value.location, "privatelink.azurecr.io")
  resource_group_name = data.azurerm_resource_group.this.name
  soa_record {
    email = "hostmaster.${data.azuread_domains.admin.domains[0].domain_name}"
    ttl   = 3600
    tags  = local.dns_tags_private
  }
  tags = azurerm_resource_group.this.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}

resource "azurerm_private_dns_zone" "privatelink-regions-dns3" {
  for_each = { for k, v in local.regions : k => v if var.private_endpoints_always_deployed == true }

  name                = format("%s.%s", each.value.location, "privatelink.afs.azure.net")
  resource_group_name = data.azurerm_resource_group.this.name
  soa_record {
    email = "hostmaster.${data.azuread_domains.admin.domains[0].domain_name}"
    ttl   = 3600
    tags  = local.dns_tags_private
  }
  tags = azurerm_resource_group.this.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}

resource "azurerm_private_dns_zone" "privatelink-regions-dns4" {
  for_each = { for k, v in local.regions : k => v if var.private_endpoints_always_deployed == true }

  name                = format("%s.%s.%s", "privatelink", each.value.location, "kusto.windows.net")
  resource_group_name = data.azurerm_resource_group.this.name
  soa_record {
    email = "hostmaster.${data.azuread_domains.admin.domains[0].domain_name}"
    ttl   = 3600
    tags  = local.dns_tags_private
  }
  tags = azurerm_resource_group.this.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}
