#####################
##  AVD Workspace  ##
#####################
resource "azurerm_virtual_desktop_workspace" "avd-workspaces" {
  for_each = { for workspace in var.avd-workspaces : workspace.name => workspace }

  name                = "${azurerm_resource_group.avd[each.key].name}-${each.key}"
  resource_group_name = azurerm_resource_group.avd[each.key].name
  location            = azurerm_resource_group.avd[each.key].location
  friendly_name       = each.value.friendly_name
  tags                = each.value.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd-workspace-app_group-association" {
  for_each = { for ag in var.avd-application_groups : ag.name => ag } # Creates one association per app group.

  application_group_id = azurerm_virtual_desktop_application_group.avd-application_groups[each.key].id
  workspace_id         = azurerm_virtual_desktop_workspace.avd-workspaces[each.value.workspace_name].id
}


######################
##  AVD Host Pools  ##
######################
resource "azurerm_virtual_desktop_host_pool" "avd-host_pools" {
  for_each = { for host_pool in var.avd-host_pools : host_pool.name => host_pool }

  name                             = "${local.prefix}-${each.key}"
  resource_group_name              = azurerm_resource_group.avd[each.value.workspace_name].name
  location                         = azurerm_resource_group.avd[each.value.workspace_name].location
  friendly_name                    = lookup(each.value, "friendly_name", null)
  description                      = lookup(each.value, "description", null)
  type                             = each.value.type
  load_balancer_type               = lookup(each.value, "load_balancer_type", null)
  validate_environment             = lookup(each.value, "validate_environment", null)
  start_vm_on_connect              = lookup(each.value, "start_vm_on_connect", null)
  custom_rdp_properties            = lookup(each.value, "custom_rdp_properties", null)
  personal_desktop_assignment_type = each.value.type == "Personal" ? lookup(each.value, "personal_desktop_assignment_type", null) : null
  maximum_sessions_allowed         = lookup(each.value, "maximum_sessions_allowed", null)
  preferred_app_group_type         = lookup(each.value, "preferred_app_group_type", null)
  tags                             = lookup(each.value, "tags", null) != null ? each.value.tags : local.tags

  dynamic "scheduled_agent_updates" {
    for_each = try(each.value.scheduled_agent_updates, null) != null ? [1] : []

    content {
      enabled                   = lookup(each.value.scheduled_agent_updates, "enabled", null)
      timezone                  = lookup(each.value.scheduled_agent_updates, "timezone", null)
      use_session_host_timezone = lookup(each.value.scheduled_agent_updates, "use_session_host_timezone", null)

      dynamic "schedule" {
        #for_each = lookup(each.value.scheduled_agent_updates, "schedule", []) != [] ? { for s in each.value.scheduled_agent_updates.schedule : s.day_of_week => s } : []
        for_each = { for s in lookup(each.value.scheduled_agent_updates, "schedule", []) : s.day_of_week => s }

        content {
          day_of_week = lookup(s.value, "day_of_week", null)
          hour_of_day = lookup(s.value, "hour_of_day", null)
        }
      }
    }
  }
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd-host_pool_registrations" {
  for_each = { for host_pool in var.avd-host_pools : host_pool.name => host_pool }

  expiration_date = each.value.registration_expiration_date
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd-host_pools[each.key].id
}


##############################
##  AVD Application Groups  ##
##############################
resource "azurerm_virtual_desktop_application_group" "avd-application_groups" {
  for_each = { for ag in var.avd-application_groups : ag.name => ag }

  name                = "${local.prefix}-${each.key}"
  friendly_name       = lookup(each.value, "friendly_name", null)
  description         = lookup(each.value, "description", null)
  resource_group_name = azurerm_resource_group.avd[each.value.workspace_name].name
  location            = azurerm_resource_group.avd[each.value.workspace_name].location
  type                = each.value.type
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd-host_pools[each.value.host_pool_name].id
  tags                = lookup(each.value, "tags", null) != null ? each.value.tags : local.tags
}

locals {
  avd-application-group-users = flatten([
    for ag in var.avd-application_groups : [
      for user in ag.avd-users != null ? ag.avd-users : [] : [
        {
          ag_key   = ag.name
          user_key = "${ag.name}-${user}"
          upn      = user
        }
      ]
    ]
  ])
}

data "azuread_user" "avd-application-groups-users" {
  for_each            = { for user in local.avd-application-group-users : user.user_key => user }
  user_principal_name = each.value.upn
}

resource "azurerm_role_assignment" "avd-application-groups-users" {
  for_each             = { for user in local.avd-application-group-users : user.user_key => user }
  scope                = azurerm_virtual_desktop_application_group.avd-application_groups[each.value.ag_key].id
  principal_id         = data.azuread_user.avd-application-groups-users[each.key].object_id
  role_definition_name = "Desktop Virtualization User"
}


########################
##  AVD Applications  ##
########################
resource "azurerm_virtual_desktop_application" "avd-applications" {
  for_each = { for app in var.avd-applications : app.name => app }

  name                         = "${local.prefix}-${each.key}"
  friendly_name                = lookup(each.value, "friendly_name", null)
  description                  = lookup(each.value, "description", null)
  application_group_id         = azurerm_virtual_desktop_application_group.avd-application_groups[each.value.application_group_name].id
  path                         = each.value.path
  command_line_argument_policy = each.value.command_line_argument_policy
  command_line_arguments       = lookup(each.value, "command_line_arguments", null)
  show_in_portal               = lookup(each.value, "show_in_portal", null)
  icon_path                    = lookup(each.value, "icon_path", null)
  icon_index                   = lookup(each.value, "icon_index", null)
}


##################################
##  AVD - Shared Image Gallery  ##
##################################
resource "azurerm_shared_image_gallery" "avd-shared_image_galleries" {
  for_each            = { for sig in var.avd-shared-image-gallery : sig.name => sig }
  name                = replace("${local.prefix}-${each.key}", "/[-_]/", "")
  description         = lookup(each.value, "description", null)
  resource_group_name = azurerm_resource_group.avd-shared_image_galleries[each.key].name
  location            = azurerm_resource_group.avd-shared_image_galleries[each.key].location
  tags                = lookup(each.value, "tags", local.tags)
}

#####################
##  AVD - FSLogix  ##
#####################
resource "azurerm_storage_account" "avd-fslogix" {
  for_each = { for sa in var.avd-fslogix : sa.name => sa }

  name                     = replace("${local.prefix}-${each.key}", "/[^[:alnum:]]/", "")
  resource_group_name      = azurerm_resource_group.avd-fslogix.name
  location                 = azurerm_resource_group.avd-fslogix.location
  tags                     = azurerm_resource_group.avd-fslogix.tags
  account_tier             = each.value.account_tier
  account_kind             = each.value.account_kind
  account_replication_type = each.value.account_replication_type
  access_tier              = each.value.access_tier

  dynamic "azure_files_authentication" {
    for_each = each.value.azure_domain_join_type != null? [1] : []

    content {
      directory_type = each.value.azure_domain_join_type
    }
  }
}

resource "azurerm_role_assignment" "avd-fslogix-smb-share-contributor-tf-deployment-spn" {
  for_each = { for sa in var.avd-fslogix : sa.name => sa if sa.azure_domain_join_type }
  principal_id         = each.value.terraform_deployment_spn_object_id
  scope                = azurerm_storage_account.avd-fslogix[each.key].id
  role_definition_name = "Storage File Data SMB Share Contributor"
}

resource "azurerm_role_assignment" "avd-fslogix-smb-share-contributor-avd-users" {
  for_each = { for sa in var.avd-fslogix : sa.name => sa if sa.azure_domain_join_type }
  principal_id         = sa.ad_group_avd_users_object_id
  scope                = azurerm_storage_account.avd-fslogix[each.key].id
  role_definition_name = "Storage File Data SMB Share Contributor"
}

###  Removed from module for the time being, as it just doesn't work, and Microsoft doesn't want to.
resource "azurerm_storage_share" "avd-fslogix-file-share" {
  for_each = { for sa in var.avd-fslogix : sa.name => sa }

  name                 = "${local.prefix}-${each.key}-share"
  storage_account_name = azurerm_storage_account.avd-fslogix[each.key].name
  access_tier          = each.value.access_tier
  quota                = each.value.azure_share_quota


  lifecycle {
    ignore_changes = [
      quota
    ]
  }
}

resource "azurerm_storage_share_directory" "avd-fslogix-file-share-directory" {
  for_each = { for sa in var.avd-fslogix : sa.name => sa }

  name                 = "${local.prefix}-${each.key}-share-directory"
  share_name           = azurerm_storage_share.avd-fslogix-file-share[each.key].name
  storage_account_name = azurerm_storage_account.avd-fslogix[each.key].name
}