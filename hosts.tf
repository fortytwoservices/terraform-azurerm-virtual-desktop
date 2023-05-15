#####################
##  Session Hosts  ##
#####################
locals {
  session_host_vms = merge([                                                    # Merges all parent maps together, leaving one map of maps
    for host in var.avd-session-hosts : {                                       # Iterates through all types of hosts from the input variable
      for i in range(host.session_host_count) : "${host.name}-${i + 1}" => host # Creates one dedicated map for each session host
    }                                                                           # based on the session_host_count parameter in the input variable
  ]...)                                                                         # ... extends the tuples into separate arguments, to allow the merge

  session_host_data_disks = merge([                                                                    # Merges all parent maps together, leaving one map of maps
    for host_key, host in local.session_host_vms : {                                                   # Iterates over all session_host_vms from the transformed list
      for disk in host.data_disks : "${host_key}-${disk.name}" => merge(disk, { host_key = host_key }) # Iterates over all data_disks defined for each vm
    }                                                                                                  # and creates a new map appending the host_key for disk attachment
  ]...)                                                                                                # ... extends the tuples into separate arguments, to allow the merge
}


resource "azurerm_availability_set" "avd-session-host-availability_sets" {
  for_each = local.session_host_vms

  name                         = "${local.prefix}-${each.key}-availability-set"
  resource_group_name          = azurerm_resource_group.avd-session_hosts[each.key].name
  location                     = azurerm_resource_group.avd-session_hosts[each.key].location
  platform_update_domain_count = lookup(each.value, "platform_update_domain_count", null)
  platform_fault_domain_count  = lookup(each.value, "platform_fault_domain_count", null)
  tags                         = lookup(each.value, "tags", local.tags)
}


resource "azurerm_storage_account" "avd-session-host-sa-boot_diagnostics" {
  for_each = local.session_host_vms

  name                     = replace("${local.prefix}-${each.key}-boot_diag", "/[-_]/", "")
  resource_group_name      = azurerm_resource_group.avd-session_hosts[each.key].name
  location                 = azurerm_resource_group.avd-session_hosts[each.key].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = lookup(each.value, "tags", local.tags)
}


resource "azurerm_network_interface" "avd-session-host-nics" {
  for_each = local.session_host_vms

  name                = "${local.prefix}-${each.key}-nic"
  resource_group_name = azurerm_resource_group.avd-session_hosts[each.key].name
  location            = azurerm_resource_group.avd-session_hosts[each.key].location
  dns_servers         = lookup(each.value, "dns_servers", null)

  ip_configuration {
    name                          = "${local.prefix}-${each.key}-nic-ipconfig01"
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = each.value.subnet_id
  }

  tags = lookup(each.value, "tags", local.tags)
}


resource "azurerm_windows_virtual_machine" "avd-session-hosts" {
  for_each = local.session_host_vms

  name                  = "${local.prefix}-${each.key}"
  resource_group_name   = azurerm_resource_group.avd-session_hosts[each.key].name
  location              = azurerm_resource_group.avd-session_hosts[each.key].location
  size                  = each.value.size
  admin_username        = each.value.admin_username
  admin_password        = each.value.admin_password
  network_interface_ids = [azurerm_network_interface.avd-session-host-nics[each.key].id]
  availability_set_id   = azurerm_availability_set.avd-session-host-availability_sets[each.key].id
  timezone              = lookup(each.value, "timezone", null)

  identity {
    type = "SystemAssigned"
  }

  dynamic "plan" {
    for_each = lookup(each.value, "plan", null) != null ? [1] : []
    content {
      name      = each.value.plan.name
      product   = each.value.plan.product
      publisher = each.value.plan.publisher
    }
  }

  ### Only one of either source_image_id or source_image_reference can be provided. If statement ensures only one of the exists.
  source_image_id = lookup(each.value, "source_image_reference", null) == null ? lookup(each.value, "source_image_id", null) : null
  dynamic "source_image_reference" {
    for_each = lookup(each.value, "source_image_id", null) == null ? (lookup(each.value, "source_image_reference", null) != null ? [1] : []) : []
    content {
      offer     = each.value.source_image_reference.offer
      publisher = each.value.source_image_reference.publisher
      sku       = each.value.source_image_reference.sku
      version   = each.value.source_image_reference.version
    }
  }

  os_disk {
    name                 = lookup(each.value.os_disk, "name", null)
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
    disk_size_gb         = each.value.os_disk.disk_size_gb
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.avd-session-host-sa-boot_diagnostics[each.key].primary_blob_endpoint
  }

  tags = lookup(each.value, "tags", local.tags)

  lifecycle {
    ignore_changes = [
      identity
    ]
  }
}


resource "azurerm_managed_disk" "avd-session-host-managed-disks" {
  for_each = local.session_host_data_disks

  name                 = each.key
  resource_group_name  = azurerm_windows_virtual_machine.avd-session-hosts[each.value.host_key].resource_group_name
  location             = azurerm_windows_virtual_machine.avd-session-hosts[each.value.host_key].location
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
  tags                 = azurerm_windows_virtual_machine.avd-session-hosts[each.value.host_key].tags
}


resource "azurerm_virtual_machine_data_disk_attachment" "avd-session-host-managed-disk-attachments" {
  for_each = local.session_host_data_disks

  virtual_machine_id = azurerm_windows_virtual_machine.avd-session-hosts[each.value.host_key].id
  managed_disk_id    = azurerm_managed_disk.avd-session-host-managed-disks[each.key].id
  lun                = each.value.lun
  caching            = each.value.caching
}


### Conditional deployment of Azure AD join
resource "azurerm_virtual_machine_extension" "avd-session-host-azuread-join" {
  for_each = { for k, v in local.session_host_vms : k => v if v.azure_domain_join_type == "azuread" ? true : false }

  name                       = "${azurerm_windows_virtual_machine.avd-session-hosts[each.key].name}-azuread-join"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd-session-hosts[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true
}

### Conditional deployment of Azure Active Directory Domain Services join
resource "azurerm_virtual_machine_extension" "avd-session-host-aadds-join" {
  for_each = { for k, v in local.session_host_vms : k => v if v.azure_domain_join_type == "aadds" ? true : false }

  name                       = "${azurerm_windows_virtual_machine.avd-session-hosts[each.key].name}-adds-join"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd-session-hosts[each.key].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "Name": "${each.value.aadds_domain_name}",
      "OUPath": "${each.value.aadds_avd_ou_path}",
      "User": "${each.value.azuread_user_dc_admin_upn}",
      "Restart": "true",
      "Options": "3"
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "Password": "${each.value.azuread_user_dc_admin_password}"
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

resource "azurerm_virtual_machine_extension" "avd-session-host-registration" {
  for_each = local.session_host_vms

  name                 = "${azurerm_windows_virtual_machine.avd-session-hosts[each.key].name}-session-host-registration"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd-session-hosts[each.key].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"

  settings = <<-SETTINGS
    {
      "modulesUrl": "${each.value.avd_session_host_registration_modules_url}",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "hostPoolName": "${azurerm_virtual_desktop_host_pool.avd-host_pools[each.value.host_pool_name].name}",
        "aadJoin": false
      }
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd-host_pool_registrations[each.value.host_pool_name].token}"
      }
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [azurerm_virtual_machine_extension.avd-session-host-aadds-join]
}