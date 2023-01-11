###############
##  Outputs  ##
###############
output "avd-host_pools" {
  value = azurerm_virtual_desktop_host_pool.avd-host_pools[*]
}

output "avd-host_pool_registrations" {
  #value = azurerm_virtual_desktop_host_pool_registration_info.avd-host_pool_registrations[*]
  value = { for hp in azurerm_virtual_desktop_host_pool_registration_info.avd-host_pool_registrations[*] : hp.key => hp }
  #value = azurerm_virtual_desktop_host_pool_registration_info.avd-host_pool_registrations["hp1"].token
}

output "avd-application_groups" {
  value = azurerm_virtual_desktop_application_group.avd-application_groups[*]
}

output "avd-applications" {
  value = azurerm_virtual_desktop_application.avd-applications[*]
}

output "avd-shared_image_galleries" {
  value = azurerm_shared_image_gallery.avd-shared_image_galleries[*]
}

output "avd-session-hosts" {
  value = azurerm_windows_virtual_machine.avd-session-hosts[*]
}

