
## User Assigned Identity#1 - Grant Graph access, so it can obtain lists of users, groups, group members and applications, but cannot make any changes
module "user-assigned-identity-graph" {
  source           = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  name = format("%s-%s", module.naming-landing-zone[var.location_key].user_assigned_identity.name_unique, "graph")

  resource_group_name = data.azurerm_resource_group.this.name
  location            = local.regions[var.location_key].location
  lock = (local.contains_real_data) ? {
    kind = local.lock_kind
    name = local.iac_message
  } : null
  tags = local.tags_default
}

data "azuread_service_principal" "identity-graph" {
  display_name = module.user-assigned-identity-graph.reosurce_id
}

resource "azuread_app_role_assignment" "user-assigned-identity-graph-user_read_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
  principal_object_id = module.user-assigned-identity-graph.resource.object_id
  resource_object_id  = data.azuread_service_principal.identity_group.object_id
}
resource "azuread_app_role_assignment" "user-assigned-identity-graph-group_read_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Group.Read.All"]
  principal_object_id = module.user-assigned-identity-graph.resource.object_id
  resource_object_id  = data.azuread_service_principal.identity_group.object_id
}
resource "azuread_app_role_assignment" "user-assigned-identity-graph-groupmember_read_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["GroupMember.Read.All"]
  principal_object_id = module.user-assigned-identity-graph.resource.object_id
  resource_object_id  = data.azuread_service_principal.identity_group.object_id
}
resource "azuread_app_role_assignment" "user-assigned-identity-graph-application_read_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Application.Read.All"]
  principal_object_id = module.user-assigned-identity-graph.resource.object_id
  resource_object_id  = data.azuread_service_principal.identity_group.object_id
}

##==============================================================================================================================
## User Assigned Identity#2 - No Graph access, just given access to the so Azure resources created throughout the Landing Zone
module "user-assigned-identity-landing_zone" {
  source           = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version          = "~>0.0, < 1.0"
  enable_telemetry = var.enable_telemetry

  name = format("%s-%s", module.naming[var.location_key].user_assigned_identity.name_unique, "zone")

  resource_group_name = data.azurerm_resource_group.this.name
  location            = local.regions[var.location_key].location
  lock = (local.contains_real_data) ? {
    kind = local.lock_kind
    name = local.iac_message
  } : null
  tags = local.tags_default
}

output "user_assigned_identity_graph_id" {
  description = "User Assigned Identity that has read-only Microsoft Graph permissions"
  sensitive   = false
  value       = module.user-assigned-identity-graph.resource.id
}

output "user_assigned_identity_landing_zone_id" {
  description = "User Assigned Identity for the Landing Zone"
  sensitive   = false
  value       = module.user-assigned-identity-landing_zone.resource.id
}

resource "azuread_group_without_members" "unified" {
  mail_enabled       = true
  security_enabled   = false
  assignable_to_role = false

  display_name = "${var.org_shortname}-${lower(var.landing_zone_name)}-Support-and-Management-Team"
  description  = "Support and Administration for the ${var.landing_zone_name} Application Landing Zone"
  owners = [
    data.azuread_client_config.current.object_id,
  ]
  prevent_duplicate_names = false

  types                   = ["Unified"]
  mail_nickname           = "lz-${lower(var.landing_zone_name)}"
  hide_from_address_lists = true
  ## external_senders_allowed = each.value.external_senders_allowed ## not supposed to work with SPs (and ti doesn't!)
  provisioning_options = ["Team"] ## create an assoicated Microsoft Teams team

  ## behaviors - (Optional) A set of behaviors for a Microsoft 365 group.
  ## Possible values are AllowOnlyMembersToPost, HideGroupInOutlook, SubscribeMembersToCalendarEventsDisabled, SubscribeNewGroupMembers, WelcomeEmailDisabled.
  behaviors = [
    "AllowOnlyMembersToPost",
    "SubscribeMembersToCalendarEventsDisabled",
    "WelcomeEmailDisabled"
  ]
  ## Blue, Green, Orange, Pink, Purple, Red or Teal
  theme = "Blue"
}

### Create Entra ID (Azure AD) Groups - PAG (Privileged Access Groups)
resource "azuread_group_without_members" "pag" {
  mail_enabled       = false
  security_enabled   = true
  assignable_to_role = true

  display_name = "PAG-${azuread_group_without_members.unified.display_name}"
  description  = "${azuread_group_without_members.unified.description} - Privileged Access Group"
  owners = [
    azuread_user.group_owner.object_id,
    data.azuread_client_config.current.object_id,
  ]
  prevent_duplicate_names = false
  ## HiddenMembership cannot be set on security enabled
  visibility = "Private" ## "Hiddenmembership" "Private" "Public", only Prviate is allowed for groups with roles.
}

output "entra_group_unified_id" {
  description = "Group ID for the Unified Group for managing the Application Landing Zone"
  sensitive   = false
  value       = module.user-assigned-identity-graph.resource.id
}

output "entra_group_pag_id" {
  description = "Group ID for the PAG Group for managing the Application Landing Zone"
  sensitive   = false
  value       = module.user-assigned-identity-landing_zone.resource.id
}
