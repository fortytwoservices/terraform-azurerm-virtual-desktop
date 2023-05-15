<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.31.0 |

## Example

```hcl
# Example, should give the user an idea about how to use this module.
# This code is found in the examples directory.
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.31.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_customer_shortname"></a> [customer\_shortname](#input\_customer\_shortname) | A short version of the customer name. Eg. Fortytwo would be ft | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | What environment the resources are deployed in. Eg. p = prod, t = test, d = dev | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | What location the resources should be deployed in. Eg. westeurope, norwayeast | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to resources. Will be applied to all resources. Sending tags will overwrite the default tags. | `any` | `null` | no |
| <a name="input_avd-workspaces"></a> [avd-workspaces](#input\_avd-workspaces) | A list of objects with one object per workspace. See documentation below for values and examples. | <pre>list(object({<br>    name          = string<br>    location      = optional(string)<br>    friendly_name = string<br>    tags          = optional(map(string))<br>  }))</pre> | n/a | yes |
| <a name="input_avd-host_pools"></a> [avd-host\_pools](#input\_avd-host\_pools) | A list of objects with one object per host pool. See documentation below for values and examples. | <pre>list(object({<br>    name                             = string<br>    friendly_name                    = optional(string)<br>    description                      = optional(string)<br>    workspace_name                   = string<br>    type                             = optional(string, "Pooled")<br>    load_balancer_type               = optional(string, "DepthFirst")<br>    validate_environment             = optional(bool, false)<br>    start_vm_on_connect              = optional(bool, false)<br>    custom_rdp_properties            = optional(string)<br>    personal_desktop_assignment_type = optional(string, "Automatic")<br>    maximum_sessions_allowed         = optional(number)<br>    preferred_app_group_type         = optional(string)<br>    tags                             = optional(map(string))<br>    scheduled_agent_updates = optional(object({<br>      enabled                   = optional(bool, false)<br>      timezone                  = optional(string)<br>      use_session_host_timezone = optional(bool, true)<br>      schedule = optional(list(object({<br>        day_of_week = string<br>        hour_of_day = number<br>      })))<br>    }))<br><br>    registration_expiration_date = optional(string)<br>  }))</pre> | n/a | yes |
| <a name="input_avd-application_groups"></a> [avd-application\_groups](#input\_avd-application\_groups) | A list of objects with one object per application group. See documentation below for values and examples. | <pre>list(object({<br>    name                         = string<br>    friendly_name                = optional(string)<br>    description                  = optional(string)<br>    type                         = string<br>    host_pool_name               = string<br>    workspace_name               = string<br>    default_desktop_display_name = optional(string)<br>    tags                         = optional(map(string))<br>    avd-users                    = optional(list(string))<br>  }))</pre> | `[]` | no |
| <a name="input_avd-applications"></a> [avd-applications](#input\_avd-applications) | A list of objects with one object per application. See documentation below for values and examples. | <pre>list(object({<br>    name                         = string<br>    friendly_name                = optional(string)<br>    description                  = optional(string)<br>    application_group_name       = string<br>    path                         = string<br>    command_line_argument_policy = string<br>    command_line_arguments       = optional(string)<br>    show_in_portal               = optional(bool)<br>    icon_path                    = optional(string)<br>    icon_index                   = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_avd-shared-image-gallery"></a> [avd-shared-image-gallery](#input\_avd-shared-image-gallery) | An object describing a Shared Image Gallery resource, if it should be deployed. | <pre>list(object({<br>    name        = string<br>    description = optional(string)<br>    tags        = optional(map(string))<br>  }))</pre> | `[]` | no |
| <a name="input_avd-fslogix"></a> [avd-fslogix](#input\_avd-fslogix) | An object describing the storage account and file share for FSLogix | <pre>list(object({<br>    name                       = string<br>    account_tier               = optional(string, "Premium")<br>    account_kind               = optional(string, "StorageV2")<br>    account_replication_type   = optional(string, "LRS")<br>    access_tier                = optional(string, "Hot")<br>    azure_files_authentication = optional(bool, false)<br>    azure_share_quota          = optional(string, "100")<br>  }))</pre> | `[]` | no |
| <a name="input_avd-session-hosts"></a> [avd-session-hosts](#input\_avd-session-hosts) | A list of objects with one object per session host. See documentation below for values and examples. | <pre>list(object({<br>    name               = string                                             # Name of session hosts<br>    session_host_count = number                                             # Number of session hosts<br>    admin_username     = string                                             # Local administrator username<br>    admin_password     = string                                             # Local administrator password<br>    size               = string                                             # VM Size SKU for the session hosts<br>    timezone           = optional(string)                                   # Specify timezone for the session hosts<br>    source_image_id    = optional(string)                                   # One of either source_image_id or source_image_reference must be set<br>    source_image_reference = optional(object({                              # Source Image Reference<br>      publisher = string                                                    # Image Publisher<br>      offer     = string                                                    # Image Offer<br>      sku       = string                                                    # Image SKU<br>      version   = string                                                    # Image Version<br>    }))                                                                     #<br>    plan = optional(object({                                                # Plan for Microsoft Marketplace image<br>      name      = string                                                    # Image Name<br>      product   = string                                                    # Image Product<br>      publisher = string                                                    # Image Publisher<br>    }))                                                                     #<br>    os_disk = object({                                                      # Operating System Disk block<br>      name                 = optional(string)                               # Name of OS disk<br>      caching              = string                                         # Caching Type. Possible values are "None", "ReadOnly", "ReadWrite"<br>      storage_account_type = string                                         # Storage Account Type. Possible values are "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"<br>      disk_size_gb         = optional(string)                               # Size of OS Disk in GigaBytes<br>    })                                                                      #<br>    subnet_id                    = string                                   # Subnet ID for the session hosts to be attached to<br>    dns_servers                  = optional(list(string))                   # Specify DNS servers for the session hosts<br>    platform_update_domain_count = optional(number)                         # Availability Set Platform Update Domain count<br>    platform_fault_domain_count  = optional(number)                         # Availability Set Platform Fault Domain count<br>    tags                         = optional(map(string))                    # Map of tags to be set. If omitted, default tags will be applied<br>    data_disks = optional(list(object({                                     # Repeatable block for additional data disks<br>      name                 = string                                         # Name of Data Disk<br>      storage_account_type = optional(string, "Standard_LRS")               # Storage Account Type for Data Disk<br>      disk_size_gb         = number                                         # Size of Data Disk in GigaBytes<br>      lun                  = number                                         # Unique LUN number for Data Disk<br>      caching              = optional(string, "None")                       # Type of Caching for Data Disk. Possible values are "None", "ReadOnly", "ReadWrite"<br>    })))                                                                    #<br>    azure_domain_join_type                    = optional(string, "azuread") # Allowed values are "azuread" and "aadds"<br>    aadds_domain_name                         = optional(string)            # Name of Azure Active Directory Domain Services to join the session hosts to<br>    aadds_avd_ou_path                         = optional(string)            # Azure Active Directory Domain Services OU Path<br>    azuread_user_dc_admin_upn                 = optional(string)            # DC Admin username<br>    azuread_user_dc_admin_password            = optional(string)            # DC Admin password<br>    avd_session_host_registration_modules_url = string                      # AVD Session Host registration modules URL<br>    host_pool_name                            = string                      # Name of Host Pool for the Session Hosts to be joined to<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_avd-host_pools"></a> [avd-host\_pools](#output\_avd-host\_pools) | ############## #  Outputs  ## ############## |
| <a name="output_avd-host_pool_registrations"></a> [avd-host\_pool\_registrations](#output\_avd-host\_pool\_registrations) | n/a |
| <a name="output_avd-application_groups"></a> [avd-application\_groups](#output\_avd-application\_groups) | n/a |
| <a name="output_avd-applications"></a> [avd-applications](#output\_avd-applications) | n/a |
| <a name="output_avd-shared_image_galleries"></a> [avd-shared\_image\_galleries](#output\_avd-shared\_image\_galleries) | n/a |
| <a name="output_avd-session-hosts"></a> [avd-session-hosts](#output\_avd-session-hosts) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_availability_set.avd-session-host-availability_sets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_managed_disk.avd-session-host-managed-disks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_network_interface.avd-session-host-nics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_resource_group.avd](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group.avd-fslogix](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group.avd-session_hosts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group.avd-shared_image_galleries](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.avd-application-groups-users](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_shared_image_gallery.avd-shared_image_galleries](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image_gallery) | resource |
| [azurerm_storage_account.avd-fslogix](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account.avd-session-host-sa-boot_diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_share.avd-fslogix-file-share](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [azurerm_storage_share_directory.avd-fslogix-file-share-directory](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share_directory) | resource |
| [azurerm_virtual_desktop_application.avd-applications](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application) | resource |
| [azurerm_virtual_desktop_application_group.avd-application_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application_group) | resource |
| [azurerm_virtual_desktop_host_pool.avd-host_pools](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool) | resource |
| [azurerm_virtual_desktop_host_pool_registration_info.avd-host_pool_registrations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool_registration_info) | resource |
| [azurerm_virtual_desktop_workspace.avd-workspaces](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace) | resource |
| [azurerm_virtual_desktop_workspace_application_group_association.avd-workspace-app_group-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace_application_group_association) | resource |
| [azurerm_virtual_machine_data_disk_attachment.avd-session-host-managed-disk-attachments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.avd-session-host-aadds-join](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.avd-session-host-registration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.avd-session-hosts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
| [azuread_user.avd-application-groups-users](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user) | data source |
<!-- END_TF_DOCS -->