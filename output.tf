###############
##  Outputs  ##
###############
output "avd-host_pools" {
  description = "Outputs a list of objects for each Host Pool created"
  value = azurerm_virtual_desktop_host_pool.avd-host_pools[*]
}

output "avd-host_pool_registrations" {
  description = "Outputs a list of objects for each Host Pool created"
  value = azurerm_virtual_desktop_host_pool_registration_info.avd-host_pool_registrations[*]
}

output "avd-application_groups" {
  description = "Outputs a list of objects for each Application Group created"
  value = azurerm_virtual_desktop_application_group.avd-application_groups[*]
}

output "avd-applications" {
  description = "Outputs a list of objects for each Application created"
  value = azurerm_virtual_desktop_application.avd-applications[*]
}

output "avd-shared_image_galleries" {
  description = "Outputs a list of objects for each Shared Image Gallery created"
  value = azurerm_shared_image_gallery.avd-shared_image_galleries[*]
}

output "avd-session-hosts" {
  description = "Outputs a list of objects for each set of Session Hosts, and each Session Host created"
  value = azurerm_windows_virtual_machine.avd-session-hosts[*]
}

