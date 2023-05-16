#######################
##  Resource Groups  ##
#######################
resource "azurerm_resource_group" "avd" {
  for_each = { for workspace in var.avd-workspaces : workspace.name => workspace }
  name     = "${local.prefix}-${each.key}"
  location = each.value.location != null ? each.value.location : var.location
  tags     = each.value.tags != null ? each.value.tags : ( var.tags != null ? var.tags : local.tags )
}

resource "azurerm_resource_group" "avd-session_hosts" {
  for_each = local.session_host_vms
  name     = "${local.prefix}-${each.key}"
  location = var.location
  tags     = each.value.tags != null ? each.value.tags : ( var.tags != null ? var.tags : local.tags )
}

resource "azurerm_role_assignment" "avd-virtual-machine-user-login" {
  for_each = local.session_host_vms
  scope = azurerm_resource_group.avd-session_hosts[each.key].id
  principal_id = each.value.group-avd-users
  role_definition_name = "Virtual Machine User Login"
}

resource "azurerm_resource_group" "avd-fslogix" {
  name     = "${local.prefix}-avd-fslogix"
  location = var.location
  tags     = var.tags != null ? var.tags : local.tags
}

resource "azurerm_resource_group" "avd-shared_image_galleries" {
  for_each = { for sig in var.avd-shared-image-gallery : sig.name => sig }
  name     = "${local.prefix}-${each.key}"
  location = var.location
  tags     = var.tags != null ? var.tags : local.tags
}