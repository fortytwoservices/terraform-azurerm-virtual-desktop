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
    for_each = try(each.value.scheduled_agent_updates, null) != null ? each.value.scheduled_agent_updates : []
    iterator = scheduled

    content {
      enabled                   = lookup(scheduled.value, "enabled", null)
      timezone                  = lookup(scheduled.value, "timezone", null)
      use_session_host_timezone = lookup(scheduled.value, "use_session_host_timezone", null)

      dynamic "schedule" {
        for_each = { for schedule in scheduled.value : schedule.day => schedule }

        content {
          day_of_week = lookup(schedule.value, "day_of_week", null)
          hour_of_day = lookup(schedule.value, "hour_of_day", null)
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
  name                = replace("${local.prefix}-${each.key}", "/[\-_]/", "")
  description         = lookup(each.value, "description", null)
  resource_group_name = azurerm_resource_group.avd-shared_image_galleries[each.key].name
  location            = azurerm_resource_group.avd-shared_image_galleries[each.key].location
  tags                = lookup(each.value, "tags", local.tags)
}
