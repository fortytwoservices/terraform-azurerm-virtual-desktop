<!-- BEGIN_TF_DOCS -->
# Terraform Module - Azure Virtual Desktop

**By Amesto Fortytwo**

---

This module deploys all resources needed for deploying Azure Virtual Desktop.

### NB!

This module does not currently deploy Azuer Files Share and Files Directory for FSLogix due to a bug in the AzureRM Terraform Provider. This step has to be completed manually in scenarios where FSLogix is needed.

## Resources deployed by this module

Which resources, and how many of each depends on your configuration
- Resource Groups
- AVD Workspaces
- AVD Host Pools
- AVD Application Groups
- AVD Applications
- Azure Shared Image Gallery
- Azure Storage Account for FSLogix
- Windows Virtual Machines as session hosts. Either joined to Azure AD or Azure Active Directory Domain Services joined. Will be registered to the specified Host Pool

*Complete list of all Terraform resources deployed is provided at the bottom of this page*

## Resources NOT deployed by this module

- Azure Virtual Network
- Azure Subnet
- Azure Network Security Groups
- Azure AD Groupsh - Typically for designating AVD Users and Admins
- Azure Key Vault - Typically for storage of secrets created by the module. Available in module outputs.
- Azure Active Directory Domain Services

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.56.0 |

## Example

```hcl
# This example contains a typical, basic deployment of an Azure Virtual Desktop environment.
# Most of the parameters and inputs are left to their default values, as they are typically the correct values in a common deployment.
# Refer to the [documentation](https://github.com/amestofortytwo/terraform-azurerm-virtual-desktop) for all available input parameters.

module "avd1" {
  source = "github.com/amestofortytwo/terraform-azurerm-virtual-desktop.git" # This referes to the latest version of the source repo. It's recommended to specify the release version!

  shortname = local.shortname    # Shortname appended to the beginning of all resources. Ommit this to not append this prefix to all resource names. Eg: Fortytwo would be ft
  env                = "dev"              # What environment the resources are deployed in. Expected values: p, prod, d, dev, t, test, q, qa, s, stage
  location           = var.location       # Default location for resources
  tags               = local.default-tags # Default tags for resources

  avd-workspaces = [                # A list of objects describing one or more AVD Workspaces
    {                               #
      name          = "ws1"         # Name of Workspace
      friendly_name = "Workspace 1" # Pretty display name for the Workspace
    }
  ]

  avd-host_pools = [                                                                  # A list of objects describing one or more AVD Host Pools
    {                                                                                 #
      name                         = "hp1"                                            # Name of Host Pool
      friendly_name                = "HostPool1"                                      # Pretty display name for the Host Pool
      description                  = "First AVD Demo host pool"                       # Description of the Host Pool. What hosts does it contain?
      workspace_name               = "ws1"                                            # Name of the AVD Workspace for the Host Pool to be associated with
      registration_expiration_date = time_offset.registration-expiration-date.rfc3339 # Time and Date in RFC3339 format that the Host Pool registration token expires. It's recommended to use the time_offset resource for this
      custom_rdp_properties        = "targetisaadjoined:i:1;"                         # A list of custom RDP properties. The one used here is needed if you plan to connec to your AVD environment from clients that are not AAD joined to the same directory
    }
  ]

  avd-application_groups = [                                                      # A list of objects describing one or more AVD Application Groups
    {                                                                             #
      name                      = "ag1"                                           # Name of the Application Group
      friendly_name             = "Application Group1"                            # Pretty display name for the Applicatino Group
      description               = "Application Group 1 for Azure Virtual Desktop" # Description of the Application Group. What does it contain?
      type                      = "Desktop"                                       # Type of Application Group. Possible values are "RemoteApp" or "Desktop"
      host_pool_name            = "hp1"                                           # Name of Host Pool to be associated with the Application Group
      workspace_name            = "ws1"                                           # Name of the Workspace to be associated with the Application Group
      group-avd-users-object-id = azuread_group.avd-users.object_id               # Group ID of the Azure AD group that contains the users that should have access to the session hosts
    }
  ]

  avd-shared-image-gallery = [                    # A list of objects describing one or more Azure Shared Image Galleries
    {                                             #
      name        = "sig1"                        # Name of the Shared Image Gallery
      description = "Test shared image gallery 1" # Description of the Shared Image Gallery
    }
  ]

  avd-fslogix = [                                                                           # A list of objects describing one or more deployments of FSLogix
    {                                                                                       #
      name                               = "fslogix"                                        # Name of the Azure Storage Account used for FSLogix
      azure_domain_join_type             = "AADKERB"                                        # Allowed values are "AD", "AADKERB", "AADDS". Defaults to "null" and no domain join is performed
      terraform_deployment_spn_object_id = azuread_service_principal.tfdeployment.object_id # Object ID of the Terraform Deployment Service Principal, to assign correct rights to the FSLogix storage account
      ad_group_avd_users_object_id       = azuread_group.avd-users.object_id                # Object ID of the Azure AD Group containing the AVD Users
    }
  ]

  avd-session-hosts = [                                                           # A list of objects describing a set of Session Hosts
    {                                                                             #
      name                      = "sh1"                                           # Name of set of Session Hosts. Each Session Host will get this name + an incrementing number
      session_host_count        = 1                                               # How many Session Hosts to be deployed in this set
      group-avd-users-object-id = azuread_group.avd-users.object_id               # Object ID of the Azure AD Group containing the AVD Users that should have access to this set of Session Hosts
      admin_username            = "marvin"                                        # Local Administrator username
      admin_password            = random_password.avd1.result                     # Local Administrator password
      subnet_id                 = azurerm_subnet.networking-infra["infra-avd"].id # Subnet ID that this set of Session Hosts should be attached to
      size                      = "Standard_DS1_v2"                               # VM Size SKU to be used for this set of Session Hosts
      source_image_reference = {                                                  # Source Image Reference
        publisher = "MicrosoftWindowsDesktop"                                     # Image Publisher
        offer     = "office-365"                                                  # Image Offer
        sku       = "win11-22h2-avd-m365"                                         # Image SKU
        version   = "22621.963.221213"                                            # Image Version
      }                                                                           #
      os_disk = {                                                                 # Operating System Disk block
        name                 = "osdisk"                                           # Name of OS disk
        caching              = "ReadWrite"                                        # Caching Type. Possible values are "None", "ReadOnly", "ReadWrite"
        storage_account_type = "Standard_LRS"                                     # Storage Account Type. Possible values are "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"
      }
      data_disks = [                 # A list of objects describing additional Data Disks to be created and attached to each Session Host
        {                            #
          name         = "datadisk1" # Name of Data Disk
          disk_size_gb = 32          # Size of Data Disk
          lun          = 0           # Unique LUN number for Data Disk
        }
      ]
      avd_session_host_registration_modules_url = local.avd_session_host_registration_modules_url # AVD Session Host registration DCS modules URL
      host_pool_name                            = "hp1"                                           # Name of the Host Pool for this set of Session Hosts to be registered to
    }
  ]

  depends_on = [                             # It is recommended to set dependencies for resources indirectly used by the module
    time_offset.registration-expiration-date # to make sure they are up to date before any changes are attempted on the resources
  ]                                          # created by the module
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.56.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_shortname"></a> [shortname](#input\_shortname) | Shortname appended to the beginning of all resources. Ommit this to not append this prefix to all resource names. Eg: Fortytwo would be ft | `string` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | What environment the resources are deployed in. Expected values: p, prod, d, dev, t, test, q, qa, s, stage | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Default location for all resources, unless specified further for any resources. Eg. westeurope, norwayeast | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to resources. Will be applied to all resources. Sending tags will overwrite the default tags. | `map(string)` | `null` | no |
| <a name="input_avd-workspaces"></a> [avd-workspaces](#input\_avd-workspaces) | A list of objects with one object per workspace. See documentation below for values and examples. | <pre>list(object({<br>    name          = string                # Name of Workspace<br>    location      = optional(string)      # Specify location of Workspace, if omitted, default location in main inputs will be used<br>    friendly_name = string                # Pretty friendly name to be displayed<br>    tags          = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied<br>  }))</pre> | n/a | yes |
| <a name="input_avd-host_pools"></a> [avd-host\_pools](#input\_avd-host\_pools) | A list of objects with one object per host pool. See documentation below for values and examples. | <pre>list(object({<br>    name                             = string                         # Name of Host Pool<br>    friendly_name                    = optional(string)               # Pretty friendly name to be displayed<br>    description                      = optional(string)               # Description of the Host Pool<br>    workspace_name                   = string                         # Workspace for the Host Pool to be associated with<br>    type                             = optional(string, "Pooled")     # Type of Host Pool. Possible values are "Pooled", "Personal". Defaults to "Pooled"<br>    load_balancer_type               = optional(string, "DepthFirst") # Load Balancer Type. Possible values are "BreadthFirst", "DepthFirst", "Persistent". "Defaults to "DepthFirst".<br>    validate_environment             = optional(bool, true)           # If environment should be validated or not. Defaults to "true"<br>    start_vm_on_connect              = optional(bool, false)          # Start VM when it's connected to. Defaults to "false"<br>    custom_rdp_properties            = optional(string)               # A string of Custom RDP Properties to be applied to the Host Pool<br>    personal_desktop_assignment_type = optional(string, "Automatic")  # Personal Desktop Assignment Type. Possible values are "Automatic" and "Direct". Defaults to "Automatic"<br>    maximum_sessions_allowed         = optional(number)               # Maximum number of users that have concurrent sessions on a session host. 0 - 999999. Should only be set if "type = Pooled"<br>    preferred_app_group_type         = optional(string)               # Preferred Application Group type for the Host Pool. Valid options are "None", "Desktop", "RailApplications". Defaults to "None"<br>    tags                             = optional(map(string))          # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied<br>    scheduled_agent_updates = optional(object({                       # Block defining Scheduled Agent Updates<br>      enabled                   = optional(bool, false)               # If Scheduled Agents Updates should be enabled or not. Defaults to "false"<br>      timezone                  = optional(string)                    # Specify timezone for the schedule<br>      use_session_host_timezone = optional(bool, true)                # Use the system timezone of the session host. Defaults to "true"<br>      schedule = optional(list(object({                               # List of blocks defining schedules<br>        day_of_week = string                                          # Specify day of week. Possible values are "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturdai", "Sunday"<br>        hour_of_day = number                                          # The hour of day the update window should start. The update is a 2 hour period following the hour provided.<br>      })))                                                            # The value should be provided as a number between 0 and 23, with 0 being midnight and 23 being 11pm.<br>    }))                                                               #<br>    registration_expiration_date = optional(string)                   # The date the registration token should expire. Recommended to use the time_offset resource for this<br>  }))</pre> | n/a | yes |
| <a name="input_avd-application_groups"></a> [avd-application\_groups](#input\_avd-application\_groups) | A list of objects with one object per application group. See documentation below for values and examples. | <pre>list(object({<br>    name                         = string                # Name of Application Group<br>    friendly_name                = optional(string)      # Pretty friendly name to be displayed<br>    description                  = optional(string)      # Description of the Application Group<br>    type                         = string                # Type of Application Group. Possible values are "RemoteApp" or "Desktop"<br>    host_pool_name               = string                # Name of Host Pool to be associated with the Application Group<br>    workspace_name               = string                # Name of the Workspace to be associated with the Application Group<br>    default_desktop_display_name = optional(string)      # Optionally set the Display Name for the default sessionDesktop desktop when "type = Desktop"<br>    tags                         = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied<br>    group-avd-users-object-id    = optional(string)      # Group ID of the Azure AD group that contains the users that should have access to the session hosts<br>  }))</pre> | `[]` | no |
| <a name="input_avd-applications"></a> [avd-applications](#input\_avd-applications) | A list of objects with one object per application. See documentation below for values and examples. | <pre>list(object({<br>    name                         = string           # Name of Application<br>    friendly_name                = optional(string) # Pretty friendly name to be displayed<br>    description                  = optional(string) # Description of the application<br>    application_group_name       = string           # Name of Application Group for the Application to be associated with<br>    path                         = string           # The file path location of the app on the Virtual Desktop OS<br>    command_line_argument_policy = string           # Specifies whether this published application can be launched with command line arguments provided by the client, command line arguments specified at publish time, or no command line arguments at all. Possible values are #DoNotAllow", "Allow", "Require"<br>    command_line_arguments       = optional(string) # Command Line Arguments for Application<br>    show_in_portal               = optional(bool)   # Specifies whether to show the RemoteApp program in the RD Web Access Server. Possible values are "true" or "false"<br>    icon_path                    = optional(string) # Specifies the path for an icon which will be used for this Application<br>    icon_index                   = optional(string) # The index of the icon you wish to use<br>  }))</pre> | `[]` | no |
| <a name="input_avd-shared-image-gallery"></a> [avd-shared-image-gallery](#input\_avd-shared-image-gallery) | An object describing a Shared Image Gallery resource, if it should be deployed. | <pre>list(object({<br>    name        = string                # Name of the Shared Image Gallery<br>    description = optional(string)      # Description of the Shared Image Gallery<br>    tags        = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied<br>  }))</pre> | `[]` | no |
| <a name="input_avd-fslogix"></a> [avd-fslogix](#input\_avd-fslogix) | An object describing the storage account and file share for FSLogix | <pre>list(object({<br>    name                               = string                          # Name of Storage Account used for FSLogix<br>    account_tier                       = optional(string, "Premium")     # Account Tier of the Storage Account. Possible values are "Standard" or "Premium". Defaults to "Premium"<br>    account_kind                       = optional(string, "FileStorage") # Storage Account kind. Possible values are "BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2". Defaults to "StorageV2"<br>    account_replication_type           = optional(string, "LRS")         # Storage Account Replication Type. Possible values are "LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS". Defaults to "LRS"<br>    access_tier                        = optional(string, "Hot")         # Storage Account Access Tier. Possible values are "Hot" or "Cool". Defaults to "Hot"<br>    azure_share_quota                  = optional(string, "100")         # The maximum size of the share, in gigabytes<br>    azure_domain_join_type             = optional(string)                # Allowed values are "AD", "AADKERB", "AADDS". Defaults to "null" and no domain join is performed<br>    terraform_deployment_spn_object_id = optional(string)                # Object ID of the Terraform Deployment Service Principal, to assign correct rights to the FSLogix storage account<br>    ad_group_avd_users_object_id       = optional(string)                # Object ID of the Azure AD Group containing the AVD Users<br>  }))</pre> | `[]` | no |
| <a name="input_avd-session-hosts"></a> [avd-session-hosts](#input\_avd-session-hosts) | A list of objects with one object per session host. See documentation below for values and examples. | <pre>list(object({<br>    name                      = string                                      # Name of session hosts<br>    session_host_count        = number                                      # Number of session hosts<br>    group-avd-users-object-id = optional(string)                            # Group ID of the Azure AD group that contains the users that should have access to the session hosts<br>    admin_username            = string                                      # Local administrator username<br>    admin_password            = string                                      # Local administrator password<br>    size                      = string                                      # VM Size SKU for the session hosts<br>    timezone                  = optional(string)                            # Specify timezone for the session hosts<br>    source_image_id           = optional(string)                            # One of either source_image_id or source_image_reference must be set<br>    source_image_reference = optional(object({                              # Source Image Reference<br>      publisher = string                                                    # Image Publisher<br>      offer     = string                                                    # Image Offer<br>      sku       = string                                                    # Image SKU<br>      version   = string                                                    # Image Version<br>    }))                                                                     #<br>    plan = optional(object({                                                # Plan for Microsoft Marketplace image<br>      name      = string                                                    # Image Name<br>      product   = string                                                    # Image Product<br>      publisher = string                                                    # Image Publisher<br>    }))                                                                     #<br>    os_disk = object({                                                      # Operating System Disk block<br>      name                 = optional(string)                               # Name of OS disk<br>      caching              = string                                         # Caching Type. Possible values are "None", "ReadOnly", "ReadWrite"<br>      storage_account_type = string                                         # Storage Account Type. Possible values are "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"<br>      disk_size_gb         = optional(string)                               # Size of OS Disk in GigaBytes<br>    })                                                                      #<br>    subnet_id                    = string                                   # Subnet ID for the session hosts to be attached to<br>    dns_servers                  = optional(list(string))                   # Specify DNS servers for the session hosts<br>    platform_update_domain_count = optional(number)                         # Availability Set Platform Update Domain count<br>    platform_fault_domain_count  = optional(number)                         # Availability Set Platform Fault Domain count<br>    tags                         = optional(map(string))                    # Map of tags to be set. If omitted, default tags will be applied<br>    data_disks = optional(list(object({                                     # Repeatable block for additional data disks<br>      name                 = string                                         # Name of Data Disk<br>      storage_account_type = optional(string, "Standard_LRS")               # Storage Account Type for Data Disk<br>      disk_size_gb         = number                                         # Size of Data Disk in GigaBytes<br>      lun                  = number                                         # Unique LUN number for Data Disk<br>      caching              = optional(string, "None")                       # Type of Caching for Data Disk. Possible values are "None", "ReadOnly", "ReadWrite"<br>    })))                                                                    #<br>    azure_domain_join_type                    = optional(string, "azuread") # Allowed values are "azuread" and "aadds"<br>    aadds_domain_name                         = optional(string)            # Name of Azure Active Directory Domain Services to join the session hosts to<br>    aadds_avd_ou_path                         = optional(string)            # Azure Active Directory Domain Services OU Path<br>    azuread_user_dc_admin_upn                 = optional(string)            # DC Admin username<br>    azuread_user_dc_admin_password            = optional(string)            # DC Admin password<br>    avd_session_host_registration_modules_url = string                      # AVD Session Host registration modules URL<br>    host_pool_name                            = string                      # Name of Host Pool for the Session Hosts to be joined to<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_avd-host_pools"></a> [avd-host\_pools](#output\_avd-host\_pools) | Outputs a list of objects for each Host Pool created |
| <a name="output_avd-host_pool_registrations"></a> [avd-host\_pool\_registrations](#output\_avd-host\_pool\_registrations) | Outputs a list of objects for each Host Pool created |
| <a name="output_avd-application_groups"></a> [avd-application\_groups](#output\_avd-application\_groups) | Outputs a list of objects for each Application Group created |
| <a name="output_avd-applications"></a> [avd-applications](#output\_avd-applications) | Outputs a list of objects for each Application created |
| <a name="output_avd-shared_image_galleries"></a> [avd-shared\_image\_galleries](#output\_avd-shared\_image\_galleries) | Outputs a list of objects for each Shared Image Gallery created |
| <a name="output_avd-session-hosts"></a> [avd-session-hosts](#output\_avd-session-hosts) | Outputs a list of objects for each set of Session Hosts, and each Session Host created |

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
| [azurerm_role_assignment.avd-fslogix-smb-share-contributor-avd-users](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.avd-fslogix-smb-share-contributor-tf-deployment-spn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.avd-virtual-machine-user-login](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_shared_image_gallery.avd-shared_image_galleries](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image_gallery) | resource |
| [azurerm_storage_account.avd-fslogix](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account.avd-session-host-sa-boot_diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_virtual_desktop_application.avd-applications](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application) | resource |
| [azurerm_virtual_desktop_application_group.avd-application_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application_group) | resource |
| [azurerm_virtual_desktop_host_pool.avd-host_pools](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool) | resource |
| [azurerm_virtual_desktop_host_pool_registration_info.avd-host_pool_registrations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool_registration_info) | resource |
| [azurerm_virtual_desktop_workspace.avd-workspaces](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace) | resource |
| [azurerm_virtual_desktop_workspace_application_group_association.avd-workspace-app_group-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace_application_group_association) | resource |
| [azurerm_virtual_machine_data_disk_attachment.avd-session-host-managed-disk-attachments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.avd-session-host-aadds-join](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.avd-session-host-azuread-join](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.avd-session-host-registration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.avd-session-hosts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
<!-- END_TF_DOCS -->