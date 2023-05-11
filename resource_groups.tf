#######################
##  Resource Groups  ##
#######################
resource "azurerm_resource_group" "avd" {
  for_each = { for workspace in var.avd-workspaces : workspace.name => workspace }
  name     = "${local.prefix}-${each.key}"
  location = each.value.location != null ? each.value.location : var.location
  tags     = each.value.tags != null ? each.value.tags : local.tags
}

resource "azurerm_resource_group" "avd-session_hosts" {
  for_each = local.session_host_vms
  name     = "${local.prefix}-${each.key}"
  location = var.location
  tags     = each.value.tags != null ? each.value.tags : local.tags
}

resource "azurerm_resource_group" "avd-fslogix" {
  name     = "${local.prefix}-avd-fslogix"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "avd-shared_image_galleries" {
  for_each = { for sig in var.avd-shared-image-gallery : sig.name => sig }
  name     = "${local.prefix}-${each.key}"
  location = var.location
  tags     = local.tags
}