<!-- BEGIN_TF_DOCS -->
# Terraform Module - Azure Virtual Desktop

---

This module deploys all resources needed for deploying Azure Virtual Desktop.

| :exclamation:  NB! |
|---|
| Due to the renaming of Company, the Github organization has changed name from "amestofortytwo" to "fortytwoservices". Pre-existing Terraform code would need to change that in code. |

| :exclamation:  NB! |
|---|
| This module does not currently deploy Azure Files Share and Files Directory for FSLogix due to a bug in the AzureRM Terraform Provider. This step has to be completed manually in scenarios where FSLogix is needed. |

## Resources deployed by this module

Which resources, and how many of each depends on your configuration

- Resource Groups
- AVD Workspaces
- AVD Host Pools
- AVD Application Groups
- AVD Applications
- Azure Shared Image Gallery
- Azure Storage Account for FSLogix
- Windows Virtual Machines as session hosts. Either joined to Entra ID or Azure Active Directory Domain Services joined. Will be registered to the specified Host Pool

Complete list of all Terraform resources deployed is provided at the bottom of this page.

## Resources NOT deployed by this module

- Azure Virtual Network
- Azure Subnet
- Azure Network Security Groups
- Entra ID Groups - Typically for designating AVD Users and Admins
- Azure Key Vault - Typically for storage of secrets created by the module. Available in module outputs.
- Azure Active Directory Domain Services

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>=3.56.0)

## Examples

### Basic example

```hcl
# This example contains a typical, basic deployment of an Azure Virtual Desktop environment.
# Most of the parameters and inputs are left to their default values, as they are typically the correct values in a common deployment.
# Refer to the [documentation](https://github.com/fortytwoservices/terraform-azurerm-virtual-desktop) for all available input parameters.

module "avd1" {
  source  = "fortytwoservices/virtual-desktop/azurerm"
  version = "2.1.0"

  shortname = local.shortname    # Shortname appended to the beginning of all resources. Ommit this to not append this prefix to all resource names. Eg: Fortytwo would be ft
  env       = "dev"              # What environment the resources are deployed in. Expected values: p, prod, d, dev, t, test, q, qa, s, stage
  location  = var.location       # Default location for resources
  tags      = local.default-tags # Default tags for resources

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

### Advanced Example

```hcl

```

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>=3.56.0)

## Resources

The following resources are used by this module:

- [azurerm_availability_set.avd-session-host-availability_sets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) (resource)
- [azurerm_managed_disk.avd-session-host-managed-disks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) (resource)
- [azurerm_network_interface.avd-session-host-nics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_resource_group.avd](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.avd-fslogix](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.avd-session_hosts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.avd-shared_image_galleries](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.avd-application-groups-users](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.avd-fslogix-smb-share-contributor-avd-users](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.avd-fslogix-smb-share-contributor-tf-deployment-spn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.avd-virtual-machine-user-login](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_shared_image_gallery.avd-shared_image_galleries](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image_gallery) (resource)
- [azurerm_storage_account.avd-fslogix](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_account.avd-session-host-sa-boot_diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_virtual_desktop_application.avd-applications](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application) (resource)
- [azurerm_virtual_desktop_application_group.avd-application_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application_group) (resource)
- [azurerm_virtual_desktop_host_pool.avd-host_pools](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool) (resource)
- [azurerm_virtual_desktop_host_pool_registration_info.avd-host_pool_registrations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool_registration_info) (resource)
- [azurerm_virtual_desktop_workspace.avd-workspaces](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace) (resource)
- [azurerm_virtual_desktop_workspace_application_group_association.avd-workspace-app_group-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace_application_group_association) (resource)
- [azurerm_virtual_machine_data_disk_attachment.avd-session-host-managed-disk-attachments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) (resource)
- [azurerm_virtual_machine_extension.avd-session-host-aadds-join](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) (resource)
- [azurerm_virtual_machine_extension.avd-session-host-azuread-join](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) (resource)
- [azurerm_virtual_machine_extension.avd-session-host-registration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) (resource)
- [azurerm_windows_virtual_machine.avd-session-hosts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_avd-host_pools"></a> [avd-host\_pools](#input\_avd-host\_pools)

Description: A list of objects with one object per host pool. See documentation below for values and examples.

Type:

```hcl
list(object({
    name                             = string                         # Name of Host Pool
    friendly_name                    = optional(string)               # Pretty friendly name to be displayed
    description                      = optional(string)               # Description of the Host Pool
    workspace_name                   = string                         # Workspace for the Host Pool to be associated with
    type                             = optional(string, "Pooled")     # Type of Host Pool. Possible values are "Pooled", "Personal". Defaults to "Pooled"
    load_balancer_type               = optional(string, "DepthFirst") # Load Balancer Type. Possible values are "BreadthFirst", "DepthFirst", "Persistent". "Defaults to "DepthFirst".
    validate_environment             = optional(bool, true)           # If environment should be validated or not. Defaults to "true"
    start_vm_on_connect              = optional(bool, false)          # Start VM when it's connected to. Defaults to "false"
    custom_rdp_properties            = optional(string)               # A string of Custom RDP Properties to be applied to the Host Pool
    personal_desktop_assignment_type = optional(string, "Automatic")  # Personal Desktop Assignment Type. Possible values are "Automatic" and "Direct". Defaults to "Automatic"
    maximum_sessions_allowed         = optional(number)               # Maximum number of users that have concurrent sessions on a session host. 0 - 999999. Should only be set if "type = Pooled"
    preferred_app_group_type         = optional(string)               # Preferred Application Group type for the Host Pool. Valid options are "None", "Desktop", "RailApplications". Defaults to "None"
    tags                             = optional(map(string))          # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
    scheduled_agent_updates = optional(object({                       # Block defining Scheduled Agent Updates
      enabled                   = optional(bool, false)               # If Scheduled Agents Updates should be enabled or not. Defaults to "false"
      timezone                  = optional(string)                    # Specify timezone for the schedule
      use_session_host_timezone = optional(bool, true)                # Use the system timezone of the session host. Defaults to "true"
      schedule = optional(list(object({                               # List of blocks defining schedules
        day_of_week = string                                          # Specify day of week. Possible values are "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturdai", "Sunday"
        hour_of_day = number                                          # The hour of day the update window should start. The update is a 2 hour period following the hour provided.
      })))                                                            # The value should be provided as a number between 0 and 23, with 0 being midnight and 23 being 11pm.
    }))                                                               #
    registration_expiration_date = optional(string)                   # The date the registration token should expire. Recommended to use the time_offset resource for this
  }))
```

### <a name="input_avd-workspaces"></a> [avd-workspaces](#input\_avd-workspaces)

Description: A list of objects with one object per workspace. See documentation below for values and examples.

Type:

```hcl
list(object({
    name          = string                # Name of Workspace
    location      = optional(string)      # Specify location of Workspace, if omitted, default location in main inputs will be used
    friendly_name = string                # Pretty friendly name to be displayed
    tags          = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
  }))
```

### <a name="input_env"></a> [env](#input\_env)

Description: What environment the resources are deployed in. Expected values: p, prod, d, dev, t, test, q, qa, s, stage

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Default location for all resources, unless specified further for any resources. Eg. westeurope, norwayeast

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_avd-application_groups"></a> [avd-application\_groups](#input\_avd-application\_groups)

Description: A list of objects with one object per application group. See documentation below for values and examples.

Type:

```hcl
list(object({
    name                         = string                # Name of Application Group
    friendly_name                = optional(string)      # Pretty friendly name to be displayed
    description                  = optional(string)      # Description of the Application Group
    type                         = string                # Type of Application Group. Possible values are "RemoteApp" or "Desktop"
    host_pool_name               = string                # Name of Host Pool to be associated with the Application Group
    workspace_name               = string                # Name of the Workspace to be associated with the Application Group
    default_desktop_display_name = optional(string)      # Optionally set the Display Name for the default sessionDesktop desktop when "type = Desktop"
    tags                         = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
    group-avd-users-object-id    = optional(string)      # Group ID of the Azure AD group that contains the users that should have access to the session hosts
  }))
```

Default: `[]`

### <a name="input_avd-applications"></a> [avd-applications](#input\_avd-applications)

Description: A list of objects with one object per application. See documentation below for values and examples.

Type:

```hcl
list(object({
    name                         = string           # Name of Application
    friendly_name                = optional(string) # Pretty friendly name to be displayed
    description                  = optional(string) # Description of the application
    application_group_name       = string           # Name of Application Group for the Application to be associated with
    path                         = string           # The file path location of the app on the Virtual Desktop OS
    command_line_argument_policy = string           # Specifies whether this published application can be launched with command line arguments provided by the client, command line arguments specified at publish time, or no command line arguments at all. Possible values are #DoNotAllow", "Allow", "Require"
    command_line_arguments       = optional(string) # Command Line Arguments for Application
    show_in_portal               = optional(bool)   # Specifies whether to show the RemoteApp program in the RD Web Access Server. Possible values are "true" or "false"
    icon_path                    = optional(string) # Specifies the path for an icon which will be used for this Application
    icon_index                   = optional(string) # The index of the icon you wish to use
  }))
```

Default: `[]`

### <a name="input_avd-fslogix"></a> [avd-fslogix](#input\_avd-fslogix)

Description: An object describing the storage account and file share for FSLogix

Type:

```hcl
list(object({
    name                               = string                          # Name of Storage Account used for FSLogix
    account_tier                       = optional(string, "Premium")     # Account Tier of the Storage Account. Possible values are "Standard" or "Premium". Defaults to "Premium"
    account_kind                       = optional(string, "FileStorage") # Storage Account kind. Possible values are "BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2". Defaults to "StorageV2"
    account_replication_type           = optional(string, "LRS")         # Storage Account Replication Type. Possible values are "LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS". Defaults to "LRS"
    access_tier                        = optional(string, "Hot")         # Storage Account Access Tier. Possible values are "Hot" or "Cool". Defaults to "Hot"
    azure_share_quota                  = optional(string, "100")         # The maximum size of the share, in gigabytes
    azure_domain_join_type             = optional(string)                # Allowed values are "AD", "AADKERB", "AADDS". Defaults to "null" and no domain join is performed
    terraform_deployment_spn_object_id = optional(string)                # Object ID of the Terraform Deployment Service Principal, to assign correct rights to the FSLogix storage account
    ad_group_avd_users_object_id       = optional(string)                # Object ID of the Azure AD Group containing the AVD Users
  }))
```

Default: `[]`

### <a name="input_avd-session-hosts"></a> [avd-session-hosts](#input\_avd-session-hosts)

Description: A list of objects with one object per session host. See documentation below for values and examples.

Type:

```hcl
list(object({
    name                      = string                                      # Name of session hosts
    session_host_count        = number                                      # Number of session hosts
    group-avd-users-object-id = optional(string)                            # Group ID of the Azure AD group that contains the users that should have access to the session hosts
    admin_username            = string                                      # Local administrator username
    admin_password            = string                                      # Local administrator password
    size                      = string                                      # VM Size SKU for the session hosts
    timezone                  = optional(string)                            # Specify timezone for the session hosts
    source_image_id           = optional(string)                            # One of either source_image_id or source_image_reference must be set
    source_image_reference = optional(object({                              # Source Image Reference
      publisher = string                                                    # Image Publisher
      offer     = string                                                    # Image Offer
      sku       = string                                                    # Image SKU
      version   = string                                                    # Image Version
    }))                                                                     #
    plan = optional(object({                                                # Plan for Microsoft Marketplace image
      name      = string                                                    # Image Name
      product   = string                                                    # Image Product
      publisher = string                                                    # Image Publisher
    }))                                                                     #
    os_disk = object({                                                      # Operating System Disk block
      name                 = optional(string)                               # Name of OS disk
      caching              = string                                         # Caching Type. Possible values are "None", "ReadOnly", "ReadWrite"
      storage_account_type = string                                         # Storage Account Type. Possible values are "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"
      disk_size_gb         = optional(string)                               # Size of OS Disk in GigaBytes
    })                                                                      #
    subnet_id                    = string                                   # Subnet ID for the session hosts to be attached to
    dns_servers                  = optional(list(string))                   # Specify DNS servers for the session hosts
    platform_update_domain_count = optional(number)                         # Availability Set Platform Update Domain count
    platform_fault_domain_count  = optional(number)                         # Availability Set Platform Fault Domain count
    tags                         = optional(map(string))                    # Map of tags to be set. If omitted, default tags will be applied
    data_disks = optional(list(object({                                     # Repeatable block for additional data disks
      name                 = string                                         # Name of Data Disk
      storage_account_type = optional(string, "Standard_LRS")               # Storage Account Type for Data Disk
      disk_size_gb         = number                                         # Size of Data Disk in GigaBytes
      lun                  = number                                         # Unique LUN number for Data Disk
      caching              = optional(string, "None")                       # Type of Caching for Data Disk. Possible values are "None", "ReadOnly", "ReadWrite"
    })))                                                                    #
    azure_domain_join_type                    = optional(string, "azuread") # Allowed values are "azuread" and "aadds"
    aadds_domain_name                         = optional(string)            # Name of Azure Active Directory Domain Services to join the session hosts to
    aadds_avd_ou_path                         = optional(string)            # Azure Active Directory Domain Services OU Path
    azuread_user_dc_admin_upn                 = optional(string)            # DC Admin username
    azuread_user_dc_admin_password            = optional(string)            # DC Admin password
    avd_session_host_registration_modules_url = string                      # AVD Session Host registration modules URL
    host_pool_name                            = string                      # Name of Host Pool for the Session Hosts to be joined to
  }))
```

Default: `[]`

### <a name="input_avd-shared-image-gallery"></a> [avd-shared-image-gallery](#input\_avd-shared-image-gallery)

Description: An object describing a Shared Image Gallery resource, if it should be deployed.

Type:

```hcl
list(object({
    name        = string                # Name of the Shared Image Gallery
    description = optional(string)      # Description of the Shared Image Gallery
    tags        = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
  }))
```

Default: `[]`

### <a name="input_shortname"></a> [shortname](#input\_shortname)

Description: Shortname appended to the beginning of all resources. Ommit this to not append this prefix to all resource names. Eg: Fortytwo would be ft

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Tags to be applied to resources. Will be applied to all resources. Sending tags will overwrite the default tags.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_avd-application_groups"></a> [avd-application\_groups](#output\_avd-application\_groups)

Description: Outputs a list of objects for each Application Group created

### <a name="output_avd-applications"></a> [avd-applications](#output\_avd-applications)

Description: Outputs a list of objects for each Application created

### <a name="output_avd-host_pool_registrations"></a> [avd-host\_pool\_registrations](#output\_avd-host\_pool\_registrations)

Description: Outputs a list of objects for each Host Pool created

### <a name="output_avd-host_pools"></a> [avd-host\_pools](#output\_avd-host\_pools)

Description: Outputs a list of objects for each Host Pool created

### <a name="output_avd-session-hosts"></a> [avd-session-hosts](#output\_avd-session-hosts)

Description: Outputs a list of objects for each set of Session Hosts, and each Session Host created

### <a name="output_avd-shared_image_galleries"></a> [avd-shared\_image\_galleries](#output\_avd-shared\_image\_galleries)

Description: Outputs a list of objects for each Shared Image Gallery created

## Modules

No modules.

<!-- END_TF_DOCS -->