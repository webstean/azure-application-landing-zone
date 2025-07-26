/*
locals {
  default_domain = data.azuread_domains.default.domains[0].domain_name
}
*/

resource "azurerm_dns_zone" "this" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags_default
  lifecycle {
    ignore_changes = [tags.created]
  }
}

output "dns_zone_name" {
  description = "Created DNS Zone Name"
  sensitive   = false
  value       = azurerm_dns_zone.this.name
}

resource "azurerm_dns_a_record" "test" {
  name                = "testme"
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = azurerm_resource_group.this.name
  records             = ["8.8.8.8", "8.8.4.4", "1.1.1.1"]
  ttl                 = 300
  tags                = local.tags_default
  lifecycle {
    ignore_changes = [tags.created]
  }
}

resource "azurerm_dns_txt_record" "msrdc" {

  name                = "_msradc"
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 300

  record {
    ## Windows 365 / DevBox - https://<rdweb-dns-name>.<domain>/RDWeb/Feed/webfeed.aspx
    value = "rdweb.${replace(azurerm_dns_zone.this.name, ".", "-")}/RDWeb/Feed/webfeed.aspx"
  }

  tags = local.tags_default
  lifecycle {
    ignore_changes = [tags.created]
  }
}

## APP DNS public sub-zone
resource "azurerm_dns_zone" "app" {
  name                = format("%s.%s", "app", azurerm_dns_zone.this.name)
  resource_group_name = azurerm_resource_group.this.name
  tags                = azurerm_resource_group.this.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}
resource "azurerm_dns_ns_record" "app" {
  name                = "app" # only the flat name not the fqdn
  resource_group_name = azurerm_resource_group.this.name
  zone_name           = azurerm_dns_zone.this.name
  records             = azurerm_dns_zone.this.name_servers
  ttl                 = 300

  tags = local.tags_default
  lifecycle {
    ignore_changes = [tags.created]
  }
}
output "app_dns_zone_name" {
  description = "Created DNS API Zone Name"
  sensitive   = false
  value       = azurerm_dns_zone.app.name
}

## API DNS public sub-zone
resource "azurerm_dns_zone" "api" {
  name                = format("%s.%s", "api", azurerm_dns_zone.this.name)
  resource_group_name = azurerm_resource_group.this.name
  tags                = azurerm_resource_group.this.tags
  lifecycle {
    ignore_changes = [tags.created]
  }
}
resource "azurerm_dns_ns_record" "api" {
  name                = "api" # only the flat name not the fqdn
  resource_group_name = azurerm_resource_group.this.name
  zone_name           = azurerm_dns_zone.this.name
  records             = azurerm_dns_zone.api.name_servers
  ttl                 = 300

  tags = local.tags_default
  lifecycle {
    ignore_changes = [tags.created]
  }
}
output "api_dns_zone_name" {
  description = "Created DNS API Zone Name"
  sensitive   = false
  value       = azurerm_dns_zone.api.name
}

resource "azurerm_dns_caa_record" "cas" {
  for_each = tomap(azurerm_dns_zone.this.name, azurerm_dns_zone.app.name, azurerm_dns_zone.api.name)

  name                = "@"
  zone_name           = each.value.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 300

  record {
    flags = 0
    tag   = "issue"
    value = "letsencrypt.org"
  }
  record {
    flags = 0
    tag   = "issuewild"
    value = "letsencrypt.org"
  }

  record {
    flags = 0
    tag   = "issue"
    value = "godaddy.com"
  }
  record {
    flags = 0
    tag   = "issuewild"
    value = "godaddy.com"
  }

  record {
    flags = 0
    tag   = "issue"
    value = "pki.goog"
  }
  record {
    flags = 0
    tag   = "issuewild"
    value = "pki.goog"
  }

  record {
    flags = 0
    tag   = "issue"
    value = "digcert.com"
  }

  record {
    flags = 0
    tag   = "issuewild"
    value = "digcert.com"
  }

  tags = local.tags_default
  lifecycle {
    ignore_changes = [tags.created]
  }
}
